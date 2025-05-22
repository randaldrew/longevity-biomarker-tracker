/* =====================================================================
   DEMO USERS & DATA  –  Longevity Biomarker Tracker
   v3  ·  collision-free (SEQN 99-00-001 → 99-00-006)
       ·  idempotent   (safe to re-run)
       ·  no temp tables (uses subqueries)
   ===================================================================== */

/*-----------------------------------------------------------------------
  1 · DEMO USERS
  --------------------------------------------------------------------*/
INSERT INTO User (SEQN, BirthDate, Sex, RaceEthnicity)
VALUES
  (9900001, '1995-03-15', 'F', 'Non-Hispanic White'),
  (9900002, '1978-11-22', 'M', 'Non-Hispanic White'),
  (9900003, '1985-08-20', 'F', 'Hispanic'),
  (9900004, '1998-12-05', 'M', 'African American'),
  (9900005, '1951-07-18', 'F', 'Asian'),
  (9900006, '1965-04-30', 'M', 'Mixed Race')
ON DUPLICATE KEY UPDATE
  BirthDate      = VALUES(BirthDate),
  Sex            = VALUES(Sex),
  RaceEthnicity  = VALUES(RaceEthnicity);

/*-----------------------------------------------------------------------
  2 · MEASUREMENT SESSIONS  (one row per lab visit)
  --------------------------------------------------------------------*/
INSERT INTO MeasurementSession (UserID, SessionDate, FastingStatus)
SELECT UserID, '2024-05-01', 1
FROM User WHERE SEQN BETWEEN 9900001 AND 9900006
UNION ALL
SELECT UserID, '2023-11-01', 1
FROM User WHERE SEQN = 9900003
UNION ALL
SELECT UserID, '2023-05-01', 1
FROM User WHERE SEQN = 9900003
ON DUPLICATE KEY UPDATE
  FastingStatus = VALUES(FastingStatus);

/*-----------------------------------------------------------------------
  3 · ANTHROPOMETRY
  --------------------------------------------------------------------*/
INSERT INTO Anthropometry (UserID, ExamDate, HeightCM, WeightKG, BMI)
SELECT UserID, '2024-05-01', 165.0, 60.0, 22.0  FROM User WHERE SEQN = 9900001
UNION ALL
SELECT UserID, '2024-05-01', 178.0, 90.5, 28.5  FROM User WHERE SEQN = 9900002
UNION ALL
SELECT UserID, '2023-05-01', 162.0, 65.5, 25.0  FROM User WHERE SEQN = 9900003
UNION ALL
SELECT UserID, '2023-11-01', 162.0, 63.0, 24.0  FROM User WHERE SEQN = 9900003
UNION ALL
SELECT UserID, '2024-05-01', 162.0, 61.5, 23.5  FROM User WHERE SEQN = 9900003
UNION ALL
SELECT UserID, '2024-05-01', 175.0, 95.5, 31.2  FROM User WHERE SEQN = 9900004
UNION ALL
SELECT UserID, '2024-05-01', 158.0, 59.5, 23.8  FROM User WHERE SEQN = 9900005
UNION ALL
SELECT UserID, '2024-05-01', 172.0, 78.5, 26.5  FROM User WHERE SEQN = 9900006
ON DUPLICATE KEY UPDATE
  HeightCM = VALUES(HeightCM),
  WeightKG = VALUES(WeightKG),
  BMI      = VALUES(BMI);

/*-----------------------------------------------------------------------
  4 · BIOMARKER MEASUREMENTS
       – nine biomarkers per session
       – subquery to find SessionID
  --------------------------------------------------------------------*/

/* ---------- Persona 1 : Healthy Young Professional ---------- */
INSERT INTO Measurement (SessionID, BiomarkerID, Value, TakenAt)
SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900001 AND ms.SessionDate = '2024-05-01'),
    1, 4.5, '2024-05-01 09:30:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900001 AND ms.SessionDate = '2024-05-01'),
    2, 65.0, '2024-05-01 09:30:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900001 AND ms.SessionDate = '2024-05-01'),
    3, 0.8, '2024-05-01 09:30:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900001 AND ms.SessionDate = '2024-05-01'),
    4, 85.0, '2024-05-01 09:30:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900001 AND ms.SessionDate = '2024-05-01'),
    5, 0.8, '2024-05-01 09:30:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900001 AND ms.SessionDate = '2024-05-01'),
    6, 5.5, '2024-05-01 09:30:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900001 AND ms.SessionDate = '2024-05-01'),
    7, 35.0, '2024-05-01 09:30:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900001 AND ms.SessionDate = '2024-05-01'),
    8, 88.0, '2024-05-01 09:30:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900001 AND ms.SessionDate = '2024-05-01'),
    9, 12.5, '2024-05-01 09:30:00'
ON DUPLICATE KEY UPDATE Value = VALUES(Value);

/* ---------- Persona 2 : Aging Executive ---------- */
INSERT INTO Measurement (SessionID, BiomarkerID, Value, TakenAt)
SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900002 AND ms.SessionDate = '2024-05-01'),
    1, 3.8, '2024-05-01 10:15:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900002 AND ms.SessionDate = '2024-05-01'),
    2, 105.0, '2024-05-01 10:15:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900002 AND ms.SessionDate = '2024-05-01'),
    3, 1.10, '2024-05-01 10:15:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900002 AND ms.SessionDate = '2024-05-01'),
    4, 98.0, '2024-05-01 10:15:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900002 AND ms.SessionDate = '2024-05-01'),
    5, 3.2, '2024-05-01 10:15:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900002 AND ms.SessionDate = '2024-05-01'),
    6, 7.8, '2024-05-01 10:15:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900002 AND ms.SessionDate = '2024-05-01'),
    7, 25.0, '2024-05-01 10:15:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900002 AND ms.SessionDate = '2024-05-01'),
    8, 94.0, '2024-05-01 10:15:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900002 AND ms.SessionDate = '2024-05-01'),
    9, 14.0, '2024-05-01 10:15:00'
ON DUPLICATE KEY UPDATE Value = VALUES(Value);

/* ---------- Persona 3 : Wellness Enthusiast (Session 1 - 2023-05-01) ---------- */
INSERT INTO Measurement (SessionID, BiomarkerID, Value, TakenAt)
SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900003 AND ms.SessionDate = '2023-05-01'),
    1, 4.0, '2023-05-01 08:45:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900003 AND ms.SessionDate = '2023-05-01'),
    2, 95.0, '2023-05-01 08:45:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900003 AND ms.SessionDate = '2023-05-01'),
    3, 0.95, '2023-05-01 08:45:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900003 AND ms.SessionDate = '2023-05-01'),
    4, 97.0, '2023-05-01 08:45:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900003 AND ms.SessionDate = '2023-05-01'),
    5, 2.8, '2023-05-01 08:45:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900003 AND ms.SessionDate = '2023-05-01'),
    6, 7.2, '2023-05-01 08:45:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900003 AND ms.SessionDate = '2023-05-01'),
    7, 28.0, '2023-05-01 08:45:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900003 AND ms.SessionDate = '2023-05-01'),
    8, 92.0, '2023-05-01 08:45:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900003 AND ms.SessionDate = '2023-05-01'),
    9, 13.8, '2023-05-01 08:45:00'
ON DUPLICATE KEY UPDATE Value = VALUES(Value);

/* ---------- Persona 3 : Wellness Enthusiast (Session 2 - 2023-11-01) ---------- */
INSERT INTO Measurement (SessionID, BiomarkerID, Value, TakenAt)
SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900003 AND ms.SessionDate = '2023-11-01'),
    1, 4.2, '2023-11-01 09:00:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900003 AND ms.SessionDate = '2023-11-01'),
    2, 82.0, '2023-11-01 09:00:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900003 AND ms.SessionDate = '2023-11-01'),
    3, 0.88, '2023-11-01 09:00:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900003 AND ms.SessionDate = '2023-11-01'),
    4, 90.0, '2023-11-01 09:00:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900003 AND ms.SessionDate = '2023-11-01'),
    5, 1.8, '2023-11-01 09:00:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900003 AND ms.SessionDate = '2023-11-01'),
    6, 6.5, '2023-11-01 09:00:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900003 AND ms.SessionDate = '2023-11-01'),
    7, 31.0, '2023-11-01 09:00:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900003 AND ms.SessionDate = '2023-11-01'),
    8, 90.0, '2023-11-01 09:00:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900003 AND ms.SessionDate = '2023-11-01'),
    9, 13.2, '2023-11-01 09:00:00'
ON DUPLICATE KEY UPDATE Value = VALUES(Value);

/* ---------- Persona 3 : Wellness Enthusiast (Session 3 - 2024-05-01) ---------- */
INSERT INTO Measurement (SessionID, BiomarkerID, Value, TakenAt)
SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900003 AND ms.SessionDate = '2024-05-01'),
    1, 4.3, '2024-05-01 08:30:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900003 AND ms.SessionDate = '2024-05-01'),
    2, 75.0, '2024-05-01 08:30:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900003 AND ms.SessionDate = '2024-05-01'),
    3, 0.85, '2024-05-01 08:30:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900003 AND ms.SessionDate = '2024-05-01'),
    4, 87.0, '2024-05-01 08:30:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900003 AND ms.SessionDate = '2024-05-01'),
    5, 1.2, '2024-05-01 08:30:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900003 AND ms.SessionDate = '2024-05-01'),
    6, 6.0, '2024-05-01 08:30:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900003 AND ms.SessionDate = '2024-05-01'),
    7, 33.0, '2024-05-01 08:30:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900003 AND ms.SessionDate = '2024-05-01'),
    8, 89.0, '2024-05-01 08:30:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900003 AND ms.SessionDate = '2024-05-01'),
    9, 12.8, '2024-05-01 08:30:00'
ON DUPLICATE KEY UPDATE Value = VALUES(Value);

/* ---------- Persona 4 : Pre-diabetic Student ---------- */
INSERT INTO Measurement (SessionID, BiomarkerID, Value, TakenAt)
SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900004 AND ms.SessionDate = '2024-05-01'),
    1, 4.2, '2024-05-01 11:00:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900004 AND ms.SessionDate = '2024-05-01'),
    2, 85.0, '2024-05-01 11:00:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900004 AND ms.SessionDate = '2024-05-01'),
    3, 0.90, '2024-05-01 11:00:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900004 AND ms.SessionDate = '2024-05-01'),
    4, 115.0, '2024-05-01 11:00:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900004 AND ms.SessionDate = '2024-05-01'),
    5, 4.5, '2024-05-01 11:00:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900004 AND ms.SessionDate = '2024-05-01'),
    6, 8.2, '2024-05-01 11:00:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900004 AND ms.SessionDate = '2024-05-01'),
    7, 28.0, '2024-05-01 11:00:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900004 AND ms.SessionDate = '2024-05-01'),
    8, 90.0, '2024-05-01 11:00:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900004 AND ms.SessionDate = '2024-05-01'),
    9, 13.8, '2024-05-01 11:00:00'
ON DUPLICATE KEY UPDATE Value = VALUES(Value);

/* ---------- Persona 5 : Active Senior ---------- */
INSERT INTO Measurement (SessionID, BiomarkerID, Value, TakenAt)
SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900005 AND ms.SessionDate = '2024-05-01'),
    1, 4.1, '2024-05-01 09:45:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900005 AND ms.SessionDate = '2024-05-01'),
    2, 78.0, '2024-05-01 09:45:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900005 AND ms.SessionDate = '2024-05-01'),
    3, 1.00, '2024-05-01 09:45:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900005 AND ms.SessionDate = '2024-05-01'),
    4, 89.0, '2024-05-01 09:45:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900005 AND ms.SessionDate = '2024-05-01'),
    5, 1.5, '2024-05-01 09:45:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900005 AND ms.SessionDate = '2024-05-01'),
    6, 6.2, '2024-05-01 09:45:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900005 AND ms.SessionDate = '2024-05-01'),
    7, 32.0, '2024-05-01 09:45:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900005 AND ms.SessionDate = '2024-05-01'),
    8, 91.0, '2024-05-01 09:45:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900005 AND ms.SessionDate = '2024-05-01'),
    9, 13.0, '2024-05-01 09:45:00'
ON DUPLICATE KEY UPDATE Value = VALUES(Value);

/* ---------- Persona 6 : Chronic Disease Patient ---------- */
INSERT INTO Measurement (SessionID, BiomarkerID, Value, TakenAt)
SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900006 AND ms.SessionDate = '2024-05-01'),
    1, 3.2, '2024-05-01 10:30:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900006 AND ms.SessionDate = '2024-05-01'),
    2, 135.0, '2024-05-01 10:30:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900006 AND ms.SessionDate = '2024-05-01'),
    3, 1.80, '2024-05-01 10:30:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900006 AND ms.SessionDate = '2024-05-01'),
    4, 145.0, '2024-05-01 10:30:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900006 AND ms.SessionDate = '2024-05-01'),
    5, 8.5, '2024-05-01 10:30:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900006 AND ms.SessionDate = '2024-05-01'),
    6, 9.5, '2024-05-01 10:30:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900006 AND ms.SessionDate = '2024-05-01'),
    7, 22.0, '2024-05-01 10:30:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900006 AND ms.SessionDate = '2024-05-01'),
    8, 96.0, '2024-05-01 10:30:00'
UNION ALL SELECT
    (SELECT SessionID FROM MeasurementSession ms
     JOIN User u ON ms.UserID = u.UserID
     WHERE u.SEQN = 9900006 AND ms.SessionDate = '2024-05-01'),
    9, 15.5, '2024-05-01 10:30:00'
ON DUPLICATE KEY UPDATE Value = VALUES(Value);

/*-----------------------------------------------------------------------
  5 · BIOLOGICAL-AGE RESULTS  (Phenotypic-Age model = ModelID 1)
  --------------------------------------------------------------------*/
INSERT INTO BiologicalAgeResult (UserID, ModelID, BioAgeYears, ComputedAt)
SELECT UserID, 1, 24.2, '2024-05-01 09:45:00' FROM User WHERE SEQN=9900001
UNION ALL SELECT UserID, 1, 52.1, '2024-05-01 10:30:00' FROM User WHERE SEQN=9900002
UNION ALL SELECT UserID, 1, 41.3, '2023-05-01 09:00:00' FROM User WHERE SEQN=9900003
UNION ALL SELECT UserID, 1, 38.7, '2023-11-01 09:15:00' FROM User WHERE SEQN=9900003
UNION ALL SELECT UserID, 1, 35.2, '2024-05-01 08:45:00' FROM User WHERE SEQN=9900003
UNION ALL SELECT UserID, 1, 32.1, '2024-05-01 11:15:00' FROM User WHERE SEQN=9900004
UNION ALL SELECT UserID, 1, 68.3, '2024-05-01 10:00:00' FROM User WHERE SEQN=9900005
UNION ALL SELECT UserID, 1, 65.8, '2024-05-01 10:45:00' FROM User WHERE SEQN=9900006
ON DUPLICATE KEY UPDATE BioAgeYears = VALUES(BioAgeYears);

/* --------------------------------------------------------------------
   ✓ Demo data loaded (idempotent & SEQN-collision-free)
   Re-run `make seed-demo` any time without errors.
   ------------------------------------------------------------------ */
