# Database Schema Summary

## Tables

### Anthropometry

| Column | Type | Constraints |
|--------|------|-------------|
| AnthroID | INTEGER | PK, NOT NULL, AUTO_INCREMENT |
| UserID | INTEGER | NOT NULL |
| ExamDate | DATE | NOT NULL, AUTO_INCREMENT |
| HeightCM | DECIMAL(5, 2) | AUTO_INCREMENT |
| WeightKG | DECIMAL(5, 2) | AUTO_INCREMENT |
| BMI | DECIMAL(4, 2) | AUTO_INCREMENT |
| CreatedAt | TIMESTAMP | AUTO_INCREMENT |

**Foreign Keys:**
- UserID → User.UserID

### User

| Column | Type | Constraints |
|--------|------|-------------|
| UserID | INTEGER | PK, NOT NULL, AUTO_INCREMENT |
| SEQN | INTEGER |  |
| BirthDate | DATE | AUTO_INCREMENT |
| Sex | ENUM | AUTO_INCREMENT |
| RaceEthnicity | VARCHAR(50) | AUTO_INCREMENT |
| CreatedAt | TIMESTAMP | AUTO_INCREMENT |

### BiologicalAgeModel

| Column | Type | Constraints |
|--------|------|-------------|
| ModelID | INTEGER | PK, NOT NULL, AUTO_INCREMENT |
| ModelName | VARCHAR(100) | AUTO_INCREMENT |
| Description | TEXT | AUTO_INCREMENT |
| FormulaJSON | JSON | AUTO_INCREMENT |
| CreatedAt | TIMESTAMP | AUTO_INCREMENT |

### BiologicalAgeResult

| Column | Type | Constraints |
|--------|------|-------------|
| ResultID | INTEGER | PK, NOT NULL, AUTO_INCREMENT |
| UserID | INTEGER | NOT NULL |
| ModelID | INTEGER | NOT NULL |
| BioAgeYears | DECIMAL(5, 2) | NOT NULL, AUTO_INCREMENT |
| ComputedAt | TIMESTAMP | NOT NULL, AUTO_INCREMENT |
| CreatedAt | TIMESTAMP | AUTO_INCREMENT |

**Foreign Keys:**
- ModelID → BiologicalAgeModel.ModelID
- UserID → User.UserID

### Biomarker

| Column | Type | Constraints |
|--------|------|-------------|
| BiomarkerID | INTEGER | PK, NOT NULL, AUTO_INCREMENT |
| Name | VARCHAR(100) | NOT NULL, AUTO_INCREMENT |
| NHANESVarCode | VARCHAR(20) | AUTO_INCREMENT |
| Units | VARCHAR(20) | NOT NULL, AUTO_INCREMENT |
| Description | TEXT | AUTO_INCREMENT |
| CreatedAt | TIMESTAMP | AUTO_INCREMENT |

### Measurement

| Column | Type | Constraints |
|--------|------|-------------|
| MeasurementID | INTEGER | PK, NOT NULL, AUTO_INCREMENT |
| SessionID | INTEGER | NOT NULL |
| BiomarkerID | INTEGER | NOT NULL |
| Value | DECIMAL(12, 4) | NOT NULL, AUTO_INCREMENT |
| TakenAt | TIMESTAMP | NOT NULL, AUTO_INCREMENT |
| CreatedAt | TIMESTAMP | AUTO_INCREMENT |

**Foreign Keys:**
- BiomarkerID → Biomarker.BiomarkerID
- SessionID → MeasurementSession.SessionID

### MeasurementSession

| Column | Type | Constraints |
|--------|------|-------------|
| SessionID | INTEGER | PK, NOT NULL, AUTO_INCREMENT |
| UserID | INTEGER | NOT NULL |
| SessionDate | DATE | NOT NULL, AUTO_INCREMENT |
| FastingStatus | TINYINT |  |
| CreatedAt | TIMESTAMP | AUTO_INCREMENT |

**Foreign Keys:**
- UserID → User.UserID

### ModelUsesBiomarker

| Column | Type | Constraints |
|--------|------|-------------|
| ModelID | INTEGER | PK, NOT NULL |
| BiomarkerID | INTEGER | PK, NOT NULL |
| Coefficient | DECIMAL(10, 6) | AUTO_INCREMENT |
| Transform | VARCHAR(50) | AUTO_INCREMENT |
| CreatedAt | TIMESTAMP | AUTO_INCREMENT |

**Foreign Keys:**
- ModelID → BiologicalAgeModel.ModelID
- BiomarkerID → Biomarker.BiomarkerID

### ReferenceRange

| Column | Type | Constraints |
|--------|------|-------------|
| RangeID | INTEGER | PK, NOT NULL, AUTO_INCREMENT |
| BiomarkerID | INTEGER | NOT NULL |
| RangeType | ENUM | NOT NULL, AUTO_INCREMENT |
| Sex | ENUM | AUTO_INCREMENT |
| AgeMin | INTEGER |  |
| AgeMax | INTEGER |  |
| MinVal | DECIMAL(12, 4) | AUTO_INCREMENT |
| MaxVal | DECIMAL(12, 4) | AUTO_INCREMENT |
| CreatedAt | TIMESTAMP | AUTO_INCREMENT |

**Foreign Keys:**
- BiomarkerID → Biomarker.BiomarkerID
