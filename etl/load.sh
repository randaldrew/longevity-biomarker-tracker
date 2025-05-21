#!/usr/bin/env bash
# ETL Load Script – Longevity Biomarker Tracker
# ---------------------------------------------
#  * requires MySQL 8 container started via `make db`
#  * run from repo root with:  bash etl/load.sh  (or `make etl`)

# 0 · Environment ---------------------------------------------------------------
cd "$(dirname "$0")"/..            # always repo root
set -a && source .env && set +a    # pulls MYSQL_* vars

echo "Starting data load process..."

# 1 · Skip gracefully if transform hasn’t produced CSVs yet ---------------------
if ! ls data/clean/*.csv >/dev/null 2>&1; then
  echo "[WARN] No clean CSVs found – run transform first."
  exit 0
fi

# 2 · Idempotence – clear tables (child → parent) ------------------------------
echo "Clearing existing rows..."
mysql -h127.0.0.1 -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "
  SET FOREIGN_KEY_CHECKS = 0;
    TRUNCATE TABLE Measurement;
    TRUNCATE TABLE MeasurementSession;
    TRUNCATE TABLE Anthropometry;
    TRUNCATE TABLE User;
  SET FOREIGN_KEY_CHECKS = 1;
"

# helper so we don’t repeat flags
MYSQL_CMD="mysql --local-infile=1 -h127.0.0.1 -P$MYSQL_PORT -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE"

# 3 · Users --------------------------------------------------------------------
echo "Loading Users..."
$MYSQL_CMD -e "
  LOAD DATA LOCAL INFILE 'data/clean/users.csv'
  INTO TABLE User
    FIELDS TERMINATED BY ','  ENCLOSED BY '\"'
    LINES  TERMINATED BY '\n'
    IGNORE 1 ROWS
    (SEQN, BirthDate, Sex, RaceEthnicity);
"

# 4 · Sessions -----------------------------------------------------------------
echo "Loading MeasurementSessions..."
$MYSQL_CMD -e "
  LOAD DATA LOCAL INFILE 'data/clean/sessions.csv'
  INTO TABLE MeasurementSession
    FIELDS TERMINATED BY ','  ENCLOSED BY '\"'
    LINES  TERMINATED BY '\n'
    IGNORE 1 ROWS
    (UserID, SessionDate, FastingStatus);
"

# 5 · Anthropometry (staging → final) ------------------------------------------
echo "Loading Anthropometry..."
$MYSQL_CMD -e "
  DROP TEMPORARY TABLE IF EXISTS anthro_staging;
  CREATE TEMPORARY TABLE anthro_staging (
      SEQN       INT,
      ExamDate   DATE,
      HeightCM   DECIMAL(5,2),
      WeightKG   DECIMAL(5,2),
      BMI        DECIMAL(4,2)
  );

  LOAD DATA LOCAL INFILE 'data/clean/anthropometry.csv'
  INTO TABLE anthro_staging
    FIELDS TERMINATED BY ','  ENCLOSED BY '\"'
    LINES  TERMINATED BY '\n'
    IGNORE 1 ROWS
    (SEQN, ExamDate, HeightCM, WeightKG, BMI);

  INSERT INTO Anthropometry (UserID, ExamDate, HeightCM, WeightKG, BMI)
  SELECT  u.UserID, a.ExamDate, a.HeightCM, a.WeightKG, a.BMI
  FROM anthro_staging a
  JOIN User u USING (SEQN);

  DROP TEMPORARY TABLE anthro_staging;
"

# 6 · Measurements (two-phase) -------------------------------------------------
echo "Loading Measurements (staging → join)..."
$MYSQL_CMD -e "
  DROP TEMPORARY TABLE IF EXISTS measurements_staging;
  CREATE TEMPORARY TABLE measurements_staging (
      SEQN         INT,
      BiomarkerID  INT,
      Value        DECIMAL(12,4),
      SessionDate  DATE,
      TakenAt      TIMESTAMP
  );

  LOAD DATA LOCAL INFILE 'data/clean/measurements.csv'
  INTO TABLE measurements_staging
    FIELDS TERMINATED BY ','  ENCLOSED BY '\"'
    LINES  TERMINATED BY '\n'
    IGNORE 1 ROWS
    (SEQN, BiomarkerID, Value, SessionDate, TakenAt);

  INSERT INTO Measurement (SessionID, BiomarkerID, Value, TakenAt)
  SELECT  s.SessionID,
          m.BiomarkerID,
          m.Value,
          m.TakenAt
  FROM measurements_staging m
  JOIN MeasurementSession s
        ON s.UserID = m.SEQN
       AND s.SessionDate = m.SessionDate;

  DROP TEMPORARY TABLE measurements_staging;
"

# 7 · Sample dump for CI --------------------------------------------------------
echo "Creating sample dump for CI..."
> tests/sample_dump.sql   # truncate file

docker compose exec -T db mysqldump \
  --no-tablespaces --column-statistics=0 \
  -uroot -p"$MYSQL_ROOT_PASSWORD" \
  --skip-add-drop-table --skip-lock-tables \
  "$MYSQL_DATABASE"  \
  User MeasurementSession Measurement Anthropometry \
  >> tests/sample_dump.sql

echo "Sample dump written to tests/sample_dump.sql"
echo "✅ Data loading completed successfully!"
