-- Demo Users Data Script (FIXED VERSION)
-- Creates 6 realistic personas for Step 3 demonstration
-- Run this AFTER schema.sql and 01_seed.sql

-- ================================================================
-- Demo User Personas
-- ================================================================

-- Persona 1: Healthy Young Professional (Optimal values)
INSERT INTO User (UserID, SEQN, BirthDate, Sex, RaceEthnicity) VALUES
(101, 100001, '1995-03-15', 'F', 'Non-Hispanic White');

-- Persona 2: Aging Executive (Accelerated aging)
INSERT INTO User (UserID, SEQN, BirthDate, Sex, RaceEthnicity) VALUES
(102, 100002, '1978-11-22', 'M', 'Non-Hispanic White');

-- Persona 3: Wellness Enthusiast (Improving over time)
INSERT INTO User (UserID, SEQN, BirthDate, Sex, RaceEthnicity) VALUES
(103, 100003, '1985-08-20', 'F', 'Hispanic');

-- Persona 4: Pre-diabetic Student (Metabolic issues)
INSERT INTO User (UserID, SEQN, BirthDate, Sex, RaceEthnicity) VALUES
(104, 100004, '1998-12-05', 'M', 'African American');

-- Persona 5: Active Senior (Healthy aging)
INSERT INTO User (UserID, SEQN, BirthDate, Sex, RaceEthnicity) VALUES
(105, 100005, '1951-07-18', 'F', 'Asian');

-- Persona 6: Chronic Disease Patient (Multiple conditions)
INSERT INTO User (UserID, SEQN, BirthDate, Sex, RaceEthnicity) VALUES
(106, 100006, '1965-04-30', 'M', 'Mixed Race');

-- Reset AUTO_INCREMENT to avoid future collisions
ALTER TABLE User AUTO_INCREMENT = 1000;

-- ================================================================
-- Anthropometry Data
-- ================================================================

-- Persona 1: Healthy Young Professional
INSERT INTO Anthropometry (UserID, ExamDate, HeightCM, WeightKG, BMI) VALUES
(101, '2024-05-01', 165.0, 60.0, 22.0);

-- Persona 2: Aging Executive
INSERT INTO Anthropometry (UserID, ExamDate, HeightCM, WeightKG, BMI) VALUES
(102, '2024-05-01', 178.0, 90.5, 28.5);

-- Persona 3: Wellness Enthusiast (Improvement journey)
INSERT INTO Anthropometry (UserID, ExamDate, HeightCM, WeightKG, BMI) VALUES
(103, '2023-05-01', 162.0, 65.5, 25.0),  -- Starting point
(103, '2023-11-01', 162.0, 63.0, 24.0),  -- 6 months later
(103, '2024-05-01', 162.0, 61.5, 23.5);  -- Current

-- Persona 4: Pre-diabetic Student
INSERT INTO Anthropometry (UserID, ExamDate, HeightCM, WeightKG, BMI) VALUES
(104, '2024-05-01', 175.0, 95.5, 31.2);

-- Persona 5: Active Senior
INSERT INTO Anthropometry (UserID, ExamDate, HeightCM, WeightKG, BMI) VALUES
(105, '2024-05-01', 158.0, 59.5, 23.8);

-- Persona 6: Chronic Disease Patient
INSERT INTO Anthropometry (UserID, ExamDate, HeightCM, WeightKG, BMI) VALUES
(106, '2024-05-01', 172.0, 78.5, 26.5);

-- ================================================================
-- Measurement Sessions
-- ================================================================

-- Persona 1: Single recent session
INSERT INTO MeasurementSession (SessionID, UserID, SessionDate, FastingStatus) VALUES
(201, 101, '2024-05-01', 1);

-- Persona 2: Single recent session
INSERT INTO MeasurementSession (SessionID, UserID, SessionDate, FastingStatus) VALUES
(202, 102, '2024-05-01', 1);

-- Persona 3: Three sessions showing improvement
INSERT INTO MeasurementSession (SessionID, UserID, SessionDate, FastingStatus) VALUES
(203, 103, '2023-05-01', 1),
(204, 103, '2023-11-01', 1),
(205, 103, '2024-05-01', 1);

-- Persona 4: Single recent session
INSERT INTO MeasurementSession (SessionID, UserID, SessionDate, FastingStatus) VALUES
(206, 104, '2024-05-01', 1);

-- Persona 5: Single recent session
INSERT INTO MeasurementSession (SessionID, UserID, SessionDate, FastingStatus) VALUES
(207, 105, '2024-05-01', 1);

-- Persona 6: Single recent session
INSERT INTO MeasurementSession (SessionID, UserID, SessionDate, FastingStatus) VALUES
(208, 106, '2024-05-01', 1);

-- Reset AUTO_INCREMENT to avoid future collisions
ALTER TABLE MeasurementSession AUTO_INCREMENT = 300;

-- ================================================================
-- Biomarker Measurements
-- Note: BiomarkerIDs 1-9 correspond to the 9 required biomarkers
-- 1=Albumin, 2=ALP, 3=Creatinine, 4=Glucose, 5=CRP, 6=WBC, 7=Lymph%, 8=MCV, 9=RDW
-- ================================================================

-- Persona 1: Healthy Young Professional (Optimal values)
INSERT INTO Measurement (SessionID, BiomarkerID, Value, TakenAt) VALUES
(201, 1, 4.5, '2024-05-01 09:30:00'),    -- Albumin: excellent
(201, 2, 65.0, '2024-05-01 09:30:00'),   -- ALP: optimal
(201, 3, 0.8, '2024-05-01 09:30:00'),    -- Creatinine: excellent kidney function
(201, 4, 85.0, '2024-05-01 09:30:00'),   -- Glucose: optimal
(201, 5, 0.8, '2024-05-01 09:30:00'),    -- CRP: low inflammation
(201, 6, 5.5, '2024-05-01 09:30:00'),    -- WBC: perfect
(201, 7, 35.0, '2024-05-01 09:30:00'),   -- Lymph%: excellent immune function
(201, 8, 88.0, '2024-05-01 09:30:00'),   -- MCV: optimal
(201, 9, 12.5, '2024-05-01 09:30:00');   -- RDW: low variability

-- Persona 2: Aging Executive (Stress markers)
INSERT INTO Measurement (SessionID, BiomarkerID, Value, TakenAt) VALUES
(202, 1, 3.8, '2024-05-01 10:15:00'),    -- Albumin: declining
(202, 2, 105.0, '2024-05-01 10:15:00'),  -- ALP: elevated stress
(202, 3, 1.1, '2024-05-01 10:15:00'),    -- Creatinine: borderline
(202, 4, 98.0, '2024-05-01 10:15:00'),   -- Glucose: pre-diabetic range
(202, 5, 3.2, '2024-05-01 10:15:00'),    -- CRP: elevated inflammation
(202, 6, 7.8, '2024-05-01 10:15:00'),    -- WBC: stress response
(202, 7, 25.0, '2024-05-01 10:15:00'),   -- Lymph%: declining immunity
(202, 8, 94.0, '2024-05-01 10:15:00'),   -- MCV: slightly elevated
(202, 9, 14.0, '2024-05-01 10:15:00');   -- RDW: increased variability

-- Persona 3: Wellness Enthusiast - Session 1 (Baseline - 1 year ago)
INSERT INTO Measurement (SessionID, BiomarkerID, Value, TakenAt) VALUES
(203, 1, 4.0, '2023-05-01 08:45:00'),    -- Albumin: borderline
(203, 2, 95.0, '2023-05-01 08:45:00'),   -- ALP: elevated
(203, 3, 0.95, '2023-05-01 08:45:00'),   -- Creatinine: high-normal
(203, 4, 97.0, '2023-05-01 08:45:00'),   -- Glucose: borderline
(203, 5, 2.8, '2023-05-01 08:45:00'),    -- CRP: elevated
(203, 6, 7.2, '2023-05-01 08:45:00'),    -- WBC: elevated
(203, 7, 28.0, '2023-05-01 08:45:00'),   -- Lymph%: low
(203, 8, 92.0, '2023-05-01 08:45:00'),   -- MCV: elevated
(203, 9, 13.8, '2023-05-01 08:45:00');   -- RDW: elevated

-- Persona 3: Wellness Enthusiast - Session 2 (Improving - 6 months ago)
INSERT INTO Measurement (SessionID, BiomarkerID, Value, TakenAt) VALUES
(204, 1, 4.2, '2023-11-01 09:00:00'),    -- Albumin: improving
(204, 2, 82.0, '2023-11-01 09:00:00'),   -- ALP: better
(204, 3, 0.88, '2023-11-01 09:00:00'),   -- Creatinine: improving
(204, 4, 90.0, '2023-11-01 09:00:00'),   -- Glucose: much better
(204, 5, 1.8, '2023-11-01 09:00:00'),    -- CRP: significant improvement
(204, 6, 6.5, '2023-11-01 09:00:00'),    -- WBC: normalizing
(204, 7, 31.0, '2023-11-01 09:00:00'),   -- Lymph%: improving
(204, 8, 90.0, '2023-11-01 09:00:00'),   -- MCV: better
(204, 9, 13.2, '2023-11-01 09:00:00');   -- RDW: improving

-- Persona 3: Wellness Enthusiast - Session 3 (Current - Excellent)
INSERT INTO Measurement (SessionID, BiomarkerID, Value, TakenAt) VALUES
(205, 1, 4.3, '2024-05-01 08:30:00'),    -- Albumin: excellent
(205, 2, 75.0, '2024-05-01 08:30:00'),   -- ALP: optimal
(205, 3, 0.85, '2024-05-01 08:30:00'),   -- Creatinine: excellent
(205, 4, 87.0, '2024-05-01 08:30:00'),   -- Glucose: optimal
(205, 5, 1.2, '2024-05-01 08:30:00'),    -- CRP: low inflammation
(205, 6, 6.0, '2024-05-01 08:30:00'),    -- WBC: perfect
(205, 7, 33.0, '2024-05-01 08:30:00'),   -- Lymph%: excellent
(205, 8, 89.0, '2024-05-01 08:30:00'),   -- MCV: optimal
(205, 9, 12.8, '2024-05-01 08:30:00');   -- RDW: good

-- Persona 4: Pre-diabetic Student (Metabolic syndrome)
INSERT INTO Measurement (SessionID, BiomarkerID, Value, TakenAt) VALUES
(206, 1, 4.2, '2024-05-01 11:00:00'),    -- Albumin: normal
(206, 2, 85.0, '2024-05-01 11:00:00'),   -- ALP: normal
(206, 3, 0.9, '2024-05-01 11:00:00'),    -- Creatinine: normal
(206, 4, 115.0, '2024-05-01 11:00:00'),  -- Glucose: pre-diabetic!
(206, 5, 4.5, '2024-05-01 11:00:00'),    -- CRP: high inflammation
(206, 6, 8.2, '2024-05-01 11:00:00'),    -- WBC: elevated
(206, 7, 28.0, '2024-05-01 11:00:00'),   -- Lymph%: low
(206, 8, 90.0, '2024-05-01 11:00:00'),   -- MCV: normal
(206, 9, 13.8, '2024-05-01 11:00:00');   -- RDW: elevated

-- Persona 5: Active Senior (Remarkably good for age)
INSERT INTO Measurement (SessionID, BiomarkerID, Value, TakenAt) VALUES
(207, 1, 4.1, '2024-05-01 09:45:00'),    -- Albumin: good for age
(207, 2, 78.0, '2024-05-01 09:45:00'),   -- ALP: excellent for age
(207, 3, 1.0, '2024-05-01 09:45:00'),    -- Creatinine: expected decline
(207, 4, 89.0, '2024-05-01 09:45:00'),   -- Glucose: excellent
(207, 5, 1.5, '2024-05-01 09:45:00'),    -- CRP: low for age
(207, 6, 6.2, '2024-05-01 09:45:00'),    -- WBC: good
(207, 7, 32.0, '2024-05-01 09:45:00'),   -- Lymph%: good for age
(207, 8, 91.0, '2024-05-01 09:45:00'),   -- MCV: normal
(207, 9, 13.0, '2024-05-01 09:45:00');   -- RDW: good

-- Persona 6: Chronic Disease Patient (Multiple abnormals)
INSERT INTO Measurement (SessionID, BiomarkerID, Value, TakenAt) VALUES
(208, 1, 3.2, '2024-05-01 10:30:00'),    -- Albumin: low (malnutrition)
(208, 2, 135.0, '2024-05-01 10:30:00'),  -- ALP: high (liver issues)
(208, 3, 1.8, '2024-05-01 10:30:00'),    -- Creatinine: elevated (kidney disease)
(208, 4, 145.0, '2024-05-01 10:30:00'),  -- Glucose: diabetic
(208, 5, 8.5, '2024-05-01 10:30:00'),    -- CRP: very high inflammation
(208, 6, 9.5, '2024-05-01 10:30:00'),    -- WBC: elevated
(208, 7, 22.0, '2024-05-01 10:30:00'),   -- Lymph%: low immunity
(208, 8, 96.0, '2024-05-01 10:30:00'),   -- MCV: elevated
(208, 9, 15.5, '2024-05-01 10:30:00');   -- RDW: high variability

-- ================================================================
-- Pre-calculated Biological Age Results
-- (Using ModelID 1 for Phenotypic Age)
-- ================================================================

INSERT INTO BiologicalAgeResult (UserID, ModelID, BioAgeYears, ComputedAt) VALUES
-- Persona 1: 4 years younger than chronological age (29 → 24.2)
(101, 1, 24.2, '2024-05-01 09:45:00'),

-- Persona 2: 7 years older than chronological age (45 → 52.1)
(102, 1, 52.1, '2024-05-01 10:30:00'),

-- Persona 3: Improving biological age over time
(103, 1, 41.3, '2023-05-01 09:00:00'),   -- Started older than chrono age
(103, 1, 38.7, '2023-11-01 09:15:00'),   -- Improving
(103, 1, 35.2, '2024-05-01 08:45:00'),   -- Now younger than chrono age (38)

-- Persona 4: 7 years older due to metabolic issues (25 → 32.1)
(104, 1, 32.1, '2024-05-01 11:15:00'),

-- Persona 5: 4 years younger despite advanced age (72 → 68.3)
(105, 1, 68.3, '2024-05-01 10:00:00'),

-- Persona 6: Significant acceleration due to disease (58 → 65.8)
(106, 1, 65.8, '2024-05-01 10:45:00');

-- NOTE: Only User 101 meets HD reference filter (Age 20-30 AND BMI 18.5-29.9)

-- ================================================================
-- Verification Queries (FIXED VERSIONS - Corrected LatestBioAge)
-- ================================================================

-- Verify all demo users were created (one row per user, latest bio-age by date)
SELECT
    u.UserID,
    u.SEQN,
    u.Sex,
    TIMESTAMPDIFF(YEAR, u.BirthDate, CURDATE()) AS Age,
    COUNT(m.MeasurementID) AS MeasurementCount,
    (SELECT bar2.BioAgeYears
     FROM BiologicalAgeResult bar2
     WHERE bar2.UserID = u.UserID
     ORDER BY bar2.ComputedAt DESC
     LIMIT 1) AS LatestBioAge
FROM User u
LEFT JOIN MeasurementSession s ON u.UserID = s.UserID
LEFT JOIN Measurement m ON s.SessionID = m.SessionID
WHERE u.UserID BETWEEN 101 AND 106
GROUP BY u.UserID, u.SEQN, u.Sex, u.BirthDate
ORDER BY u.UserID;

-- Check that all 9 biomarkers are present for latest sessions
SELECT
    u.UserID,
    u.SEQN,
    COUNT(DISTINCT m.BiomarkerID) AS UniqueBiomarkers,
    s.SessionDate AS LatestSession
FROM User u
JOIN (
    SELECT UserID, MAX(SessionDate) AS SessionDate
    FROM MeasurementSession
    GROUP BY UserID
) latest USING (UserID)
JOIN MeasurementSession s ON s.UserID = u.UserID AND s.SessionDate = latest.SessionDate
JOIN Measurement m ON m.SessionID = s.SessionID
WHERE u.UserID BETWEEN 101 AND 106
GROUP BY u.UserID, u.SEQN, s.SessionDate
ORDER BY u.UserID;
