#!/usr/bin/env bash
# ------------------------------------------------------------------
# ETL Load Script – loads patched CSVs into MySQL 8
# • Handles SEQN→UserID and SessionID look-ups with temp tables
# • Creates a tidy sample dump for CI without privileged options
# ------------------------------------------------------------------

set -euo pipefail

# ── Move to repo root ──────────────────────────────────────────────
cd "$(dirname "$0")/.."  # script is in etl/

# ── Env vars ──────────────────────────────────────────────────────
set -a
source .env
set +a

MYSQL_HOST=${MYSQL_HOST:-127.0.0.1}
MYSQL_PORT=${MYSQL_PORT:-3307}

mysql_cmd() {
  mysql --local-infile=1 -h "$MYSQL_HOST" -P "$MYSQL_PORT" \
        -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" "$@"
}

mysqldump_cmd() {
  mysqldump --no-tablespaces -h "$MYSQL_HOST" -P "$MYSQL_PORT" \
            -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" "$@"
}

echo "Starting data load process..."

# ── Ensure CSVs present ────────────────────────────────────────────
if ! ls data/clean/*.csv >/dev/null 2>&1; then
  echo "[WARN] Skipping MySQL LOAD – clean/*.csv not generated yet."
  exit 0
fi

# ── Load USERS (BirthDate already patched) ─────────────────────────
echo "Loading User ..."
mysql_cmd -e "
  LOAD DATA LOCAL INFILE 'data/clean/users.csv'
  INTO TABLE User
  FIELDS TERMINATED BY ',' ENCLOSED BY '\"'
  LINES  TERMINATED BY '\n'
  IGNORE 1 ROWS
  (SEQN, BirthDate, Sex, RaceEthnicity);
"

# ── Load MEASUREMENTSESSION (SEQN → UserID) ───────────────────────
echo "Loading MeasurementSession ..."
mysql_cmd -e "
  CREATE TEMPORARY TABLE tmp_sessions (
      SEQN INT, SessionDate DATE, FastingStatus TINYINT
  );

  LOAD DATA LOCAL INFILE 'data/clean/sessions.csv'
  INTO TABLE tmp_sessions
  FIELDS TERMINATED BY ',' ENCLOSED BY '\"'
  LINES  TERMINATED BY '\n'
  IGNORE 1 ROWS
  (SEQN, SessionDate, FastingStatus);

  INSERT IGNORE INTO MeasurementSession (UserID, SessionDate, FastingStatus)
  SELECT u.UserID, t.SessionDate, t.FastingStatus
  FROM   tmp_sessions t
  JOIN   User u USING (SEQN);

  DROP TEMPORARY TABLE tmp_sessions;
"

# ── Load MEASUREMENT (SEQN + SessionDate → SessionID) ─────────────
echo "Loading Measurement ..."
mysql_cmd -e "
  CREATE TEMPORARY TABLE tmp_meas (
      SEQN INT, SessionDate DATE,
      BiomarkerID INT, Value DECIMAL(12,4), TakenAt TIMESTAMP
  );

  LOAD DATA LOCAL INFILE 'data/clean/measurements.csv'
  INTO TABLE tmp_meas
  FIELDS TERMINATED BY ',' ENCLOSED BY '\"'
  LINES  TERMINATED BY '\n'
  IGNORE 1 ROWS
  (SEQN, SessionDate, BiomarkerID, Value, TakenAt);

  INSERT IGNORE INTO Measurement (SessionID, BiomarkerID, Value, TakenAt)
  SELECT s.SessionID, t.BiomarkerID, t.Value, t.TakenAt
  FROM   tmp_meas t
  JOIN   User u USING (SEQN)
  JOIN   MeasurementSession s
         ON s.UserID = u.UserID AND s.SessionDate = t.SessionDate;

  DROP TEMPORARY TABLE tmp_meas;
"

# ── Load ANTHROPOMETRY (optional file) ────────────────────────────
if [[ -f "data/clean/anthropometry.csv" ]]; then
  echo "Loading Anthropometry ..."
  mysql_cmd -e "
    CREATE TEMPORARY TABLE tmp_anthro (
        SEQN INT, ExamDate DATE,
        HeightCM DECIMAL(5,2), WeightKG DECIMAL(5,2), BMI DECIMAL(4,2)
    );

    LOAD DATA LOCAL INFILE 'data/clean/anthropometry.csv'
    INTO TABLE tmp_anthro
    FIELDS TERMINATED BY ',' ENCLOSED BY '\"'
    LINES  TERMINATED BY '\n'
    IGNORE 1 ROWS
    (SEQN, ExamDate, HeightCM, WeightKG, BMI);

    INSERT IGNORE INTO Anthropometry (UserID, ExamDate, HeightCM, WeightKG, BMI)
    SELECT u.UserID, t.ExamDate, t.HeightCM, t.WeightKG, t.BMI
    FROM   tmp_anthro t
    JOIN   User u USING (SEQN);

    DROP TEMPORARY TABLE tmp_anthro;
  "
else
  echo "Skipping Anthropometry (file not found)"
fi

# ── Create sample dump for CI (no LIMIT-in-subquery) ───────────────
echo "Creating sample dump for testing ..."

TOP_USERS=$(mysql_cmd -N -e \
  "SELECT GROUP_CONCAT(UserID) FROM (SELECT UserID FROM User ORDER BY CreatedAt DESC LIMIT 10) t")

# 1) Users
mysqldump_cmd User \
  --where="UserID IN ($TOP_USERS)" \
  --skip-add-drop-table --skip-lock-tables \
  > tests/sample_dump.sql

# 2) Sessions
mysqldump_cmd MeasurementSession \
  --where="UserID IN ($TOP_USERS)" \
  --no-create-info --skip-add-drop-table --skip-lock-tables \
  >> tests/sample_dump.sql

# 3) Measurements
mysqldump_cmd Measurement \
  --where="SessionID IN (SELECT SessionID FROM MeasurementSession WHERE UserID IN ($TOP_USERS))" \
  --no-create-info --skip-add-drop-table --skip-lock-tables \
  >> tests/sample_dump.sql

echo "Sample dump written to tests/sample_dump.sql"
echo "Data loading completed successfully!"

