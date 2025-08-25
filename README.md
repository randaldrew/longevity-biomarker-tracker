# Longevity Biomarker Tracking System

> **⚠️ IMPORTANT MEDICAL DISCLAIMER:**
> This is a research and educational tool only. **NOT for medical decision-making or health diagnosis.**
> - Consult healthcare professionals for all health decisions
> - Biological age calculations are population-based estimates from research studies
> - Not validated for individual health assessment or treatment planning
> - Results should not influence medical care without professional consultation

[![CI](https://github.com/randaldrew/longevity-biomarker-tracker/actions/workflows/ci.yml/badge.svg)](https://github.com/randaldrew/longevity-biomarker-tracker/actions/workflows/ci.yml)

A comprehensive database system for tracking biomarkers and calculating biological age using scientifically validated models. Built with real NHANES health survey data and implements peer-reviewed algorithms for longevity research.

## 🎯 What This Application Does

- **Track biomarkers over time** - Store and analyze 9 key health biomarkers
- **Calculate biological age** - Using validated Phenotypic Age and Homeostatic Dysregulation models
- **Compare to reference ranges** - Clinical and longevity-optimized ranges
- **Visualize trends** - Interactive web interface for data exploration
- **Research-grade data** - Built on NHANES (CDC health survey) data

## 🚀 Quick Start

### Prerequisites
- **Python 3.11+**
- **Docker & Docker Compose**
- **Git**
- **MySQL 8.0+**

### Setup (5 minutes)
```bash
# 1. Clone and navigate
git clone https://github.com/yourusername/longevity-biomarker-tracker.git
cd longevity-biomarker-tracker

# 2. Environment setup
cp .env.example .env
make install              # Creates virtual environment + installs dependencies

# 3. Start database
make db                   # Launches MySQL + Adminer web interface

# 4. Start the application (in separate terminals)
make run                  # API server → http://localhost:8000
make ui                   # Web interface → http://localhost:80

# 5. Optional: Load sample data
make etl                  # Downloads & processes NHANES data (takes ~10 min)
```

### Verify Installation
```bash
make test                 # Should pass all tests
```

Visit:
- **Web Interface:** http://localhost:80
- **API Documentation:** http://localhost:8000/docs
- **Database Admin:** http://localhost:8080 (login: biomarker_user / biomarker_pass)

## 📁 Project Structure

```
longevity-biomarker-tracker/
├── sql/                          # 🗄️ Database schema & seed data
│   ├── schema.sql                #   MySQL tables, views, indexes
│   └── 01_seed.sql               #   Biomarkers, models, reference ranges
├── src/
│   ├── api/                      # 🌐 FastAPI REST endpoints
│   │   └── main.py               #   User profiles, measurements, biological age
│   ├── analytics/                # 🧮 Scientific calculations
│   │   └── hd.py                 #   Homeostatic Dysregulation model
│   └── ui/                       # 💻 Web interface
│       ├── index.html            #   Interactive query interface
│       └── main.js               #   Biomarker visualizations
├── etl/                          # 🔄 Data pipeline
│   ├── download_nhanes.py        #   Fetch CDC health survey data
│   ├── transform.ipynb           #   Clean & normalize data
│   └── load.sh                   #   Bulk load into database
├── tests/                        # 🧪 Test suite
│   ├── test_api.py               #   API endpoint tests
│   └── test_schema.py            #   Database integrity tests
├── docker-compose.yml            # 🐳 MySQL + Adminer containers
├── Makefile                      # 🛠️ Automation commands
└── requirements.txt              # 📦 Python dependencies
```

## 🧬 Scientific Foundation

### Biological Age Models

**1. Phenotypic Age (Levine et al. 2018)**
- **Purpose:** Predicts mortality risk better than chronological age
- **Method:** Regression model trained on 9 biomarkers from NHANES data
- **Validation:** Tested on 42,000+ adults, published in *Aging*
- **Reference:** [PMID: 29676998](https://pubmed.ncbi.nlm.nih.gov/29676998/)

**2. Homeostatic Dysregulation (Cohen et al. 2013)**
- **Purpose:** Measures physiological system coordination
- **Method:** Mahalanobis distance from healthy young adult reference population
- **Innovation:** Captures multi-system aging patterns
- **Implementation Note:** We applied a linear transformation to convert HD scores to "biological age years" for comparison with Phenotypic Age - this is our methodological assumption, not from the original literature
- **Reference:** [PMID: 23376244](https://pubmed.ncbi.nlm.nih.gov/23376244/)

### Required Biomarkers (9 total)
1. **Albumin** - Protein synthesis, nutrition
2. **Alkaline Phosphatase** - Liver/bone function
3. **Creatinine** - Kidney function
4. **Fasting Glucose** - Metabolic health
5. **High-Sensitivity CRP** - Inflammation
6. **White Blood Cell Count** - Immune function
7. **Lymphocyte Percentage** - Immune cell distribution
8. **Mean Corpuscular Volume** - Red blood cell size
9. **Red Cell Distribution Width** - Blood cell variation

### Data Source
- **NHANES 2017-2018** - CDC's National Health and Nutrition Examination Survey
- **Population:** Nationally representative US adults
- **Sample Size:** 9,000+ participants with complete biomarker panels
- **Public Domain:** De-identified, freely available for research

## 🔬 Key Features

### Database Architecture
- **MySQL 8.0** with normalized schema (BCNF compliant)
- **9 core tables** with foreign key constraints and cascade rules
- **4 analytical views** for complex queries
- **Performance indexes** optimized for biomarker trend analysis

### API Endpoints
- **User Management** - Create profiles, track demographics
- **Biomarker Storage** - Time-series measurement data
- **Biological Age Calculation** - Real-time computation using validated models
- **Reference Ranges** - Clinical and longevity-optimized comparisons

### Web Interface
- **Interactive Queries** - Explore data without SQL knowledge
- **Trend Visualization** - Biomarker changes over time
- **Range Comparisons** - See how values compare to healthy populations
- **Biological Age Dashboard** - Track aging metrics

## ⚙️ Development

### Running Tests
```bash
make test                 # Full test suite
pytest tests/test_api.py  # API tests only
pytest tests/test_schema.py # Database tests only
```

### Database Management
```bash
make db                   # Start database
make db-reset             # Reset schema + seed data
make seed-demo            # Load demo users for testing
```

### Code Quality
```bash
make lint                 # Run pre-commit hooks
pre-commit run --all-files # Manual linting
```

### ETL Pipeline
```bash
make etl                  # Full pipeline: download → transform → load
python etl/download_nhanes.py  # Download only
jupyter notebook etl/transform.ipynb  # Transform only
bash etl/load.sh          # Load only
```

## 🏥 Reference Ranges

The system includes two types of reference ranges:

### Clinical Ranges
- Standard laboratory reference values
- Used by healthcare providers for diagnosis
- Based on 95% of healthy population

### Longevity Ranges
- Optimized for healthy aging
- Derived from healthiest 20-30 year olds in NHANES
- More restrictive than clinical ranges
- Research-based longevity targets

## 📊 Sample Queries

The web interface supports multiple pre-built queries including:

- **User Profiles** - Demographics and latest biomarker values
- **Biological Age Calculation** - Current aging metrics vs chronological age
- **Biomarker Trends** - Time-series analysis of individual markers
- **Range Comparisons** - Clinical vs longevity reference ranges
- **Population Analytics** - Age distributions and biomarker statistics

## 🔒 Privacy & Security

- **No PHI:** Uses de-identified NHANES research data only
- **Local Development:** All data stays on your machine
- **No External APIs:** Completely self-contained system
- **Research Use:** Designed for educational and research purposes

## 🤝 Team and Credits

### Team
This application was developed by:
- Randal Drew
- Sam Fine
- Kelly Luna Jimenez
- YD Song

The team is grateful for the support of Dr. Ahmed Khaled and his TA team for their advice and feedback.

## 📚 Academic References

1. **Levine, M. E., et al.** (2018). An epigenetic biomarker of aging for lifespan and healthspan. *Aging*, 10(4), 573-591. [PMID: 29676998](https://pubmed.ncbi.nlm.nih.gov/29676998/)

2. **Cohen, A. A., et al.** (2013). A novel statistical approach shows evidence for multi-system physiological dysregulation during aging. *Mechanisms of Ageing and Development*, 134(3-4), 110-117. [PMID: 23376244](https://pubmed.ncbi.nlm.nih.gov/23376244/)

3. **Belsky, D. W., et al.** (2015). Quantification of biological aging in young adults. *Proceedings of the National Academy of Sciences*, 112(30), [PMID: 26150497](https://pubmed.ncbi.nlm.nih.gov/26150497/).

4. **NHANES** - National Health and Nutrition Examination Survey. Centers for Disease Control and Prevention. Available at: https://www.cdc.gov/nchs/nhanes/

## 📄 License

MIT License - see LICENSE file for details.

## 🚨 Important Notes

- **Research Tool Only:** Not intended for clinical use
- **Educational Purpose:** Designed for learning about biomarker analysis
- **Data Limitations:** Based on population averages, not individual health status
- **Professional Consultation:** Always consult healthcare providers for health decisions

---

*Built with scientific rigor using peer-reviewed algorithms and real health survey data. Perfect for researchers, students, and longevity enthusiasts interested in quantified aging.*
