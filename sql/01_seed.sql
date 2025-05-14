-- Longevity Biomarker Tracker · seed data (HD VERSION v1.2)
-- ================================================================
-- Reference data with Phenotypic Age + Homeostatic Dysregulation models
-- Both models scientifically validated on NHANES data
-- ================================================================

-- Insert the 9 biomarkers needed for biological age calculations
INSERT INTO Biomarker (BiomarkerID, Name, NHANESVarCode, Units, Description) VALUES
(1, 'Albumin', 'LBXSAL', 'g/dL', 'Serum albumin concentration'),
(2, 'Alkaline Phosphatase', 'LBXSAPSI', 'U/L', 'Alkaline phosphatase enzyme activity'),
(3, 'Creatinine', 'LBXSCR', 'mg/dL', 'Serum creatinine concentration'),
(4, 'Fasting Glucose', 'LBXGLU', 'mg/dL', 'Plasma fasting glucose level'),
(5, 'High-Sensitivity CRP', 'LBXHSCRP', 'mg/L', 'High-sensitivity C-reactive protein'),
(6, 'White Blood Cell Count', 'LBXWBCSI', '10³ cells/µL', 'White blood cell count'),
(7, 'Lymphocyte Percentage', 'LBXLYPCT', '%', 'Percentage of lymphocytes in WBC'),
(8, 'Mean Corpuscular Volume', 'LBXMCVSI', 'fL', 'Average volume of red blood cells'),
(9, 'Red Cell Distribution Width', 'LBXRDW', '%', 'RBC size variation coefficient');

-- Reset auto-increment after explicit inserts
ALTER TABLE Biomarker AUTO_INCREMENT = 10;

-- Insert biological age models (UPDATED with HD)
INSERT INTO BiologicalAgeModel (ModelID, ModelName, Description, FormulaJSON) VALUES
(1, 'Phenotypic Age', 'Levine et al. 2018 Phenotypic Age based on 9 biomarkers',
 JSON_OBJECT(
   'algorithm', 'regression',
   'intercept', -19.9067,
   'age_coef', 0.0336,
   'biomarkers', 9,
   'reference', 'Levine ME et al. 2018',
   'pmid', '29676998',
   'validation', 'NHANES III'
 )),
(2, 'Homeostatic Dysregulation', 'Mahalanobis distance from healthy young adult reference',
 JSON_OBJECT(
   'algorithm', 'mahalanobis_distance',
   'reference_age_min', 20,
   'reference_age_max', 30,
   'reference_criteria', 'BMI < 30, biomarkers in clinical range',
   'distance_metric', 'Mahalanobis',
   'biomarkers', 9,
   'units', 'HD_score_or_years',
   'references', JSON_ARRAY('Cohen 2013 PMC3964022', 'Belsky 2015 PMC4693454'),
   'validation', 'Multiple NHANES cohorts'
 ));

-- Reset auto-increment after explicit inserts
ALTER TABLE BiologicalAgeModel AUTO_INCREMENT = 3;

-- Insert Phenotypic Age model biomarker coefficients (VALIDATED against Levine 2018, PMID: 29676998)
INSERT INTO ModelUsesBiomarker (ModelID, BiomarkerID, Coefficient, Transform) VALUES
(1, 1, -0.0336, 'linear'),        -- Albumin
(1, 2, 0.00188, 'linear'),        -- Alkaline phosphatase
(1, 3, 0.0095, 'linear'),         -- Creatinine
(1, 4, 0.1953, 'linear'),         -- Glucose
(1, 5, 0.0954, 'log'),            -- CRP (log-transformed)
(1, 6, 0.0554, 'log'),            -- WBC (log-transformed)
(1, 7, -0.0120, 'linear'),        -- Lymphocyte %
(1, 8, 0.0268, 'linear'),         -- MCV
(1, 9, 0.3306, 'linear');         -- RDW

-- NOTE: Homeostatic Dysregulation (ModelID=2) requires no individual coefficients
-- The algorithm uses the covariance matrix of the reference population
-- All 9 biomarkers are used but weights are data-derived, not pre-specified

-- Insert VALIDATED clinical reference ranges for each biomarker
-- Sources: Mayo Clinic, NIH/NLM, CDC guidelines

-- Albumin: 3.5-5.0 g/dL (Mayo Clinic)
INSERT INTO ReferenceRange (BiomarkerID, RangeType, Sex, AgeMin, AgeMax, MinVal, MaxVal) VALUES
(1, 'clinical', 'All', 0, 200, 3.5, 5.0);

-- Alkaline phosphatase: 44-147 U/L (Mayo Clinic, adults)
INSERT INTO ReferenceRange (BiomarkerID, RangeType, Sex, AgeMin, AgeMax, MinVal, MaxVal) VALUES
(2, 'clinical', 'All', 18, 200, 44, 147);

-- Creatinine: Sex-specific (National Library of Medicine)
INSERT INTO ReferenceRange (BiomarkerID, RangeType, Sex, AgeMin, AgeMax, MinVal, MaxVal) VALUES
(3, 'clinical', 'M', 18, 200, 0.7, 1.3),
(3, 'clinical', 'F', 18, 200, 0.6, 1.1);

-- Fasting glucose: <100 mg/dL normal (CDC)
INSERT INTO ReferenceRange (BiomarkerID, RangeType, Sex, AgeMin, AgeMax, MinVal, MaxVal) VALUES
(4, 'clinical', 'All', 0, 200, 70, 99);

-- High-sensitivity CRP: <3.0 mg/L (low cardiovascular risk)
INSERT INTO ReferenceRange (BiomarkerID, RangeType, Sex, AgeMin, AgeMax, MinVal, MaxVal) VALUES
(5, 'clinical', 'All', 0, 200, 0, 3.0);

-- WBC count: 4.5-11.0 × 10³/µL (standard hematology)
INSERT INTO ReferenceRange (BiomarkerID, RangeType, Sex, AgeMin, AgeMax, MinVal, MaxVal) VALUES
(6, 'clinical', 'All', 0, 200, 4.5, 11.0);

-- Lymphocyte %: 20-40% (standard hematology)
INSERT INTO ReferenceRange (BiomarkerID, RangeType, Sex, AgeMin, AgeMax, MinVal, MaxVal) VALUES
(7, 'clinical', 'All', 0, 200, 20, 40);

-- MCV: 82-98 fL (mean ± 2SD, NCBI)
INSERT INTO ReferenceRange (BiomarkerID, RangeType, Sex, AgeMin, AgeMax, MinVal, MaxVal) VALUES
(8, 'clinical', 'All', 0, 200, 82, 98);

-- RDW: 11.5-14.5% (standard hematology)
INSERT INTO ReferenceRange (BiomarkerID, RangeType, Sex, AgeMin, AgeMax, MinVal, MaxVal) VALUES
(9, 'clinical', 'All', 0, 200, 11.5, 14.5);

-- Insert longevity-optimized reference ranges
-- NOTE: These are heuristic ranges based on healthy young adult percentiles
-- NOT intended as clinical guidelines

INSERT INTO ReferenceRange (BiomarkerID, RangeType, Sex, AgeMin, AgeMax, MinVal, MaxVal) VALUES
-- Albumin: optimal range (higher than clinical minimum)
(1, 'longevity', 'All', 0, 200, 4.0, 4.8),

-- Alkaline phosphatase: optimal range (mid-range of normal)
(2, 'longevity', 'All', 18, 200, 60, 100),

-- Creatinine: optimal range by sex (lower than clinical maximum)
(3, 'longevity', 'M', 18, 200, 0.8, 1.1),
(3, 'longevity', 'F', 18, 200, 0.7, 0.9),

-- Fasting glucose: optimal range (tight glycemic control)
(4, 'longevity', 'All', 0, 200, 80, 90),

-- CRP: optimal range (minimal inflammation)
(5, 'longevity', 'All', 0, 200, 0, 1.0),

-- WBC: optimal range (robust but not excessive immune activity)
(6, 'longevity', 'All', 0, 200, 5.0, 8.0),

-- Lymphocyte %: optimal range (balanced immune profile)
(7, 'longevity', 'All', 0, 200, 25, 35),

-- MCV: optimal range (healthy erythropoiesis)
(8, 'longevity', 'All', 0, 200, 85, 95),

-- RDW: optimal range (uniform RBC size distribution)
(9, 'longevity', 'All', 0, 200, 12.0, 13.5);
