-- Longevity Biomarker Tracker · database schema (v1.3 - WITH ANTHROPOMETRY)
-- ================================================================
-- FINAL schema including Anthropometry table for BMI-based HD filtering
-- ================================================================

/* --------- housekeeping (idempotent) --------- */
DROP VIEW IF EXISTS
    v_user_latest_measurements,
    v_biomarker_ranges,
    v_hd_reference_candidates,
    v_user_anthro_history;

-- then the tables (children → parents)
DROP TABLE IF EXISTS BiologicalAgeResult;
DROP TABLE IF EXISTS ModelUsesBiomarker;
DROP TABLE IF EXISTS BiologicalAgeModel;
DROP TABLE IF EXISTS Anthropometry;
DROP TABLE IF EXISTS ReferenceRange;
DROP TABLE IF EXISTS Measurement;
DROP TABLE IF EXISTS Biomarker;
DROP TABLE IF EXISTS MeasurementSession;
DROP TABLE IF EXISTS User;



/* --------- User --------- */
CREATE TABLE User (
    UserID INT AUTO_INCREMENT PRIMARY KEY,
    SEQN INT UNIQUE,
    BirthDate DATE,
    Sex ENUM('M', 'F'),
    RaceEthnicity VARCHAR(50),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

/* --------- MeasurementSession --------- */
CREATE TABLE MeasurementSession (
    SessionID INT AUTO_INCREMENT PRIMARY KEY,
    UserID INT NOT NULL,
    SessionDate DATE NOT NULL,
    FastingStatus BOOLEAN,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY (UserID, SessionDate),
    CONSTRAINT fk_session_user FOREIGN KEY (UserID) REFERENCES User (UserID) ON DELETE CASCADE
);

/* --------- Biomarker --------- */
CREATE TABLE Biomarker (
    BiomarkerID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    NHANESVarCode VARCHAR(20) UNIQUE,
    Units VARCHAR(20) NOT NULL,
    Description TEXT,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

/* --------- Measurement --------- */
CREATE TABLE Measurement (
    MeasurementID INT AUTO_INCREMENT PRIMARY KEY,
    SessionID INT NOT NULL,
    BiomarkerID INT NOT NULL,
    Value DECIMAL(12, 4) NOT NULL,
    TakenAt TIMESTAMP NOT NULL,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY (SessionID, BiomarkerID),
    CONSTRAINT fk_measurement_session FOREIGN KEY (SessionID) REFERENCES MeasurementSession (
        SessionID
    ) ON DELETE CASCADE,
    CONSTRAINT fk_measurement_biomarker FOREIGN KEY (BiomarkerID) REFERENCES Biomarker (BiomarkerID) ON DELETE RESTRICT
);

/* --------- Anthropometry (NEW) --------- */
CREATE TABLE Anthropometry (
    AnthroID INT AUTO_INCREMENT PRIMARY KEY,
    UserID INT NOT NULL,
    ExamDate DATE NOT NULL,
    HeightCM DECIMAL(5, 2),
    WeightKG DECIMAL(5, 2),
    BMI DECIMAL(4, 2),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY (UserID, ExamDate),
    CONSTRAINT fk_anthro_user FOREIGN KEY (UserID) REFERENCES User (UserID) ON DELETE CASCADE
);

/* --------- ReferenceRange --------- */
CREATE TABLE ReferenceRange (
    RangeID INT AUTO_INCREMENT PRIMARY KEY,
    BiomarkerID INT NOT NULL,
    RangeType ENUM('clinical', 'longevity') NOT NULL,
    Sex ENUM('M', 'F', 'All') DEFAULT 'All',
    AgeMin INT DEFAULT 0,
    AgeMax INT DEFAULT 200,
    MinVal DECIMAL(12, 4),
    MaxVal DECIMAL(12, 4),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY (BiomarkerID, RangeType, Sex, AgeMin, AgeMax),
    CONSTRAINT fk_range_biomarker FOREIGN KEY (BiomarkerID) REFERENCES Biomarker (BiomarkerID) ON DELETE RESTRICT
);

/* --------- BiologicalAgeModel --------- */
CREATE TABLE BiologicalAgeModel (
    ModelID INT AUTO_INCREMENT PRIMARY KEY,
    ModelName VARCHAR(100) UNIQUE,
    Description TEXT,
    FormulaJSON JSON,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

/* --------- ModelUsesBiomarker (junction) --------- */
CREATE TABLE ModelUsesBiomarker (
    ModelID INT NOT NULL,
    BiomarkerID INT NOT NULL,
    Coefficient DECIMAL(10, 6),
    Transform VARCHAR(50),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ModelID, BiomarkerID),
    CONSTRAINT fk_model_uses_model FOREIGN KEY (ModelID) REFERENCES BiologicalAgeModel (ModelID) ON DELETE CASCADE,
    CONSTRAINT fk_model_uses_biomarker FOREIGN KEY (BiomarkerID) REFERENCES Biomarker (BiomarkerID) ON DELETE RESTRICT
);

/* --------- BiologicalAgeResult --------- */
CREATE TABLE BiologicalAgeResult (
    ResultID INT AUTO_INCREMENT PRIMARY KEY,
    UserID INT NOT NULL,
    ModelID INT NOT NULL,
    BioAgeYears DECIMAL(5, 2) NOT NULL,
    ComputedAt TIMESTAMP NOT NULL,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY (UserID, ModelID, ComputedAt),
    CONSTRAINT fk_bio_age_user FOREIGN KEY (UserID) REFERENCES User (UserID) ON DELETE CASCADE,
    CONSTRAINT fk_bio_age_model FOREIGN KEY (ModelID) REFERENCES BiologicalAgeModel (ModelID) ON DELETE RESTRICT
);

/* --------- Analytics Indexes --------- */
-- Covering index for trend queries (fixed to use SessionID)
CREATE INDEX Idx_Measurement_Trend ON Measurement (SessionID, BiomarkerID, TakenAt, Value);

-- Index for biomarker value analysis
CREATE INDEX Idx_Measurement_Bio_Value ON Measurement (BiomarkerID, Value);

-- Index for biological age results queries
CREATE INDEX Idx_Bio_Age_User_Model ON BiologicalAgeResult (UserID, ModelID, ComputedAt);

-- Index for anthropometry BMI lookups (covered by UNIQUE key, no additional index needed)

-- Index for anthropometry BMI lookups (covered by UNIQUE key, no additional index needed)

/* --------- Optimized Views for API/Analytics --------- */

/* View: latest measurement per biomarker per user */
CREATE VIEW v_user_latest_measurements AS
SELECT
    s.UserID,
    m.BiomarkerID,
    m.Value,
    m.TakenAt,
    b.Name  AS BiomarkerName,
    b.Units
FROM Measurement          AS m
JOIN MeasurementSession   AS s ON m.SessionID   = s.SessionID
JOIN Biomarker            AS b ON m.BiomarkerID = b.BiomarkerID
JOIN (
        SELECT
            s2.UserID,
            m2.BiomarkerID,
            MAX(m2.TakenAt) AS LatestAt
        FROM Measurement        AS m2
        JOIN MeasurementSession AS s2 ON m2.SessionID = s2.SessionID
        GROUP BY s2.UserID, m2.BiomarkerID
     ) latest
  ON  s.UserID      = latest.UserID
  AND m.BiomarkerID = latest.BiomarkerID
  AND m.TakenAt     = latest.LatestAt;

-- View for biomarkers with reference ranges
CREATE VIEW v_biomarker_ranges AS
SELECT
    B.BiomarkerID,
    B.Name,
    B.Units,
    Rr.RangeType,
    Rr.Sex,
    Rr.AgeMin,
    Rr.AgeMax,
    Rr.MinVal,
    Rr.MaxVal
FROM Biomarker AS B
LEFT JOIN ReferenceRange AS Rr ON B.BiomarkerID = Rr.BiomarkerID
ORDER BY B.BiomarkerID, Rr.RangeType;

-- HD Reference population candidates (COMPLETE with BMI filter)
CREATE VIEW v_hd_reference_candidates AS
SELECT
    U.UserID,
    U.SEQN,
    U.Sex,
    A.BMI,
    A.HeightCM,
    A.WeightKG,
    A.ExamDate,
    YEAR(CURDATE()) - YEAR(U.BirthDate) AS Age
FROM User AS U
INNER JOIN Anthropometry AS A ON U.UserID = A.UserID
WHERE
    U.BirthDate IS NOT NULL
    AND YEAR(CURDATE()) - YEAR(U.BirthDate) BETWEEN 20 AND 30
    AND A.BMI IS NOT NULL
    AND A.BMI >= 18.5
    AND A.BMI < 30.0
    -- Healthy BMI range: 18.5-29.9 kg/m² (excludes underweight and obese)
ORDER BY U.UserID;

-- View for user anthropometry trends
CREATE VIEW v_user_anthro_history AS
SELECT
    U.UserID,
    U.SEQN,
    A.ExamDate,
    A.BMI,
    A.HeightCM,
    A.WeightKG,
    CASE
        WHEN A.BMI < 18.5 THEN 'Underweight'
        WHEN A.BMI < 25.0 THEN 'Normal'
        WHEN A.BMI < 30.0 THEN 'Overweight'
        ELSE 'Obese'
    END AS BMI_Category
FROM User AS U
INNER JOIN Anthropometry AS A ON U.UserID = A.UserID
ORDER BY U.UserID, A.ExamDate;
