ma# 🧬 Longevity Biomarker Tracking System — Team Guide (v1.0 FINAL)

Welcome to the repo! This page is the **source‑of‑truth for who owns what, what lives where, and the 5‑minute routine to spin everything up locally.**

**✅ DATABASE ARCHITECTURE COMPLETE** - Schema frozen at v1.3, scientifically validated, ready for handoff!

---

## 1 · Team roles & areas of ownership

| Role                                      | Status                               | Main goals                                                 | Owns these paths                                     |
| ----------------------------------------- | ------------------------------------ | ---------------------------------------------------------- | ---------------------------------------------------- |
| **Database Architect (@db‑architect)**    | ✅ **COMPLETE** (Schema v1.3 frozen) | • keep the schema in 3 NF • publish the ER diagram         | `/sql/`, `/docs/er_diagram.*`, `/verify_db_setup.py` |
| **Data Engineer (@data‑engineer)**        | 📋 **TODO:** Transform notebook      | • pull NHANES XPTs • clean → CSVs • bulk‑load into MySQL   | `/etl/`, `/data/raw/`, `/data/clean/`, `/notebooks/` |
| **Backend Lead (@backend‑lead)**          | 📋 **TODO:** Real API endpoints      | • convert FastAPI stubs to real endpoints • add unit tests | `/src/api/`, `/tests/`                               |
| **Analytics / UI Lead (@analytics‑lead)** | 📋 **TODO:** Full dashboard          | • build dashboard • charts & tables                        | `/src/ui/`, `/src/analytics/`                        |

> **Branch etiquette** → _One feature = one branch._ Open a PR, request review from anyone whose code you touch. **CI must be green** before merge.

---

## 2 · Repository tour (birds‑eye view)

```
├── sql/                 ← DDL (schema + seed data) ✅ COMPLETE
│   ├─ schema.sql        ← v1.3 FINAL - 9 tables + 4 views + 3 indexes
│   └─ 01_seed.sql       ← Biomarkers, models, reference ranges
├── etl/                 ← download → transform → load pipeline
│   ├─ download_nhanes.py   ← ✅ Working (pulls 6 XPT files)
│   ├─ transform.ipynb      ← 📋 TODO: Data Engineer
│   └─ load.sh              ← ✅ Handles missing CSVs gracefully
├── data/
│   ├─ raw/    ← NHANES XPTs (6 files, git‑ignored) ✅ Downloaded
│   └─ clean/  ← CSVs ready for LOAD INFILE (git‑ignored)
├── src/
│   ├─ api/          ← FastAPI app ✅ Stub endpoints working
│   ├─ analytics/    ← ✅ HD calculator ready
│   └─ ui/           ← ✅ Frontend working
├── tests/           ← ✅ pytest suite passing (100%)
├── scripts/         ← ✅ Bootstrap scripts & utilities
│   ├─ bootstrap_venv.sh    ← Virtual environment setup
│   └─ codebase_snapshot.sh ← Documentation helper
├── docker-compose.yml  ← ✅ MySQL 8 + Adminer working
├── Makefile          ← ✅ All targets tested & working
├── .env.example      ← ✅ Complete configuration template
├── .github/workflows/ci.yml ← ✅ All checks passing
├── verify_db_setup.py      ← ✅ Comprehensive validation script
└── docs/             ← ✅ Complete documentation
    ├─ schema_summary.md
    └─ sqlfluff_status.md
```

### 2b · File‑by‑file cheat‑sheet

| Path                        | Status | What it is / Why it matters                                                                  |
| --------------------------- | ------ | -------------------------------------------------------------------------------------------- |
| `sql/schema.sql`            | ✅     | **FROZEN v1.3** - Complete DDL with Anthropometry table, explicit FKs, optimized views       |
| `sql/01_seed.sql`           | ✅     | Biomarkers (9), models (2), coefficients (9), reference ranges (20)                          |
| `verify_db_setup.py`        | ✅     | **Comprehensive validation** - Scientific accuracy, schema integrity, performance            |
| `etl/download_nhanes.py`    | ✅     | Pulls 6 NHANES XPT files (2017‑2018 cycle) including BMX_J for anthropometry                 |
| `etl/transform.ipynb`       | 📋     | **TODO (Data Engineer):** Clean XPTs → 4 CSVs (users, sessions, measurements, anthropometry) |
| `etl/load.sh`               | ✅     | Bulk‑loads CSVs + creates sample dump for CI. Handles missing files gracefully.              |
| `scripts/bootstrap_venv.sh` | ✅     | **Complete Python setup** - Creates .venv, installs deps, configures hooks                   |
| `docker-compose.yml`        | ✅     | MySQL 8 (port 3307) + Adminer (port 8080). Auto-loads schema on first boot.                  |
| `Makefile`                  | ✅     | **All targets verified** - `make db`, `make etl`, `make run`, `make ui`, `make test`         |
| `src/api/main.py`           | ✅📋   | FastAPI with working stub endpoints. Ready for Backend Lead to implement.                    |
| `src/ui/index.html`         | ✅📋   | Frontend for running queries and interacting with backend.                                   |
| `src/ui/main.js`            | ✅📋   | JavaScript code powering the frontend.                                                       |
| `src/analytics/hd.py`       | ✅     | **Complete HD calculator** with BMI-filtered reference population                            |
| `tests/`                    | ✅     | Full test suite passing. DB + API fixtures, schema integrity checks.                         |
| `.github/workflows/ci.yml`  | ✅     | **All checks green** - Schema validation, dependency install, test execution                 |
| `.pre-commit-config.yaml`   | ✅     | Black, flake8, trailing whitespace. **SQLFluff commented** (parsing issues with complex DDL) |

### 2c · Demo data workflow

| File                    | Purpose                                         | Usage               |
| ----------------------- | ----------------------------------------------- | ------------------- |
| `sql/demo_users.sql`    | **6 demo personas** with realistic medical data | `make seed-demo`    |
| `make seed-demo`        | Load demo users (101-106) into database         | Run after `make db` |
| `make verify-demo-data` | Check demo users loaded correctly               | Quick validation    |

**Demo Users Quick Reference:**

- **User 101:** Healthy 29F (bio-age 24) - Perfect for Q1, Q2, Q3, Q4
- **User 103:** Wellness enthusiast 38F with **3 sessions** - Star of Q5, Q6, Q7 trends
- **User 102:** Stressed executive 45M (bio-age 52) - Age acceleration demo

⚠️ **Important:** Always run `make seed-demo` after `make db-reset`

---

## 3 · Getting started locally (≈ 3 minutes)

> **Prereqs:** Docker Desktop, Python 3.11+, Git

**🚀 Complete new team member setup:**

```bash
# 1 · Clone & navigate
git clone https://github.com/<org>/longevity-biomarker-tracker
cd longevity-biomarker-tracker

# 2 · Copy environment template (edit if needed for custom ports)
cp .env.example .env

# 3 · **One-command setup** (creates .venv, installs everything, configures hooks)
make install

# 4 · Activate virtual environment
source .venv/bin/activate

# 5 · Launch database (MySQL :3307 + Adminer :8080)
make db

# 6 · **Verify everything works**
make test                    # Should be all green ✅
python verify_db_setup.py    # Comprehensive validation ✅

# 7 · Fire up services (each in a new terminal)
make run               # FastAPI on http://127.0.0.1:8000
make ui                # HTTP server on http://127.0.0.1:80
```

**✅ If all steps complete without errors, you're ready to develop!**

---

## 4 · Database Status & Schema Overview

### ✅ **Schema v1.3 (FINAL & FROZEN)**

| Component        | Count | Status                                     |
| ---------------- | ----- | ------------------------------------------ |
| **Tables**       | 9     | All created with proper constraints        |
| **Views**        | 4     | Optimized for API/analytics                |
| **Indexes**      | 3     | Performance-tuned for trend queries        |
| **Foreign Keys** | 9     | All have explicit names                    |
| **Biomarkers**   | 9     | NHANES-validated for biological age        |
| **Models**       | 2     | Phenotypic Age + Homeostatic Dysregulation |

### 🧬 **Biological Age Models (Scientifically Validated)**

| Model                         | Status       | Description                                                  |
| ----------------------------- | ------------ | ------------------------------------------------------------ |
| **Phenotypic Age**            | ✅ Validated | Levine et al. 2018 coefficients exactly matched              |
| **Homeostatic Dysregulation** | ✅ Validated | BMI-filtered reference population (20-30 yrs, BMI 18.5-29.9) |

### 📊 **Key Tables**

- **User** - Demographics (SEQN, age, sex, race/ethnicity)
- **Anthropometry** - 🆕 Height, weight, BMI for HD filtering
- **MeasurementSession** - Lab visits with fasting status
- **Measurement** - 9 biomarker values with timestamps
- **BiologicalAgeResult** - Calculated biological ages

---

## 5 · Daily workflow cheatsheet

| Action                         | Command                           | Notes                            |
| ------------------------------ | --------------------------------- | -------------------------------- |
| **Fresh start**                | `make db && make seed-demo`       | Database + demo users            |
| **Reset after schema changes** | `make db-reset && make seed-demo` | **Always re-seed after reset**   |
| **Start backend**              | `make run`                        | FastAPI with demo data ready     |
| **Start frontend**             | `make ui`                         | HTTP server                      |
| **Verify demo data**           | `make verify-demo-data`           | Check 6 users loaded correctly   |
| **Run tests**                  | `make test`                       | Uses sample dump, not demo users |

---

## 6 · Team handoff status & next steps

### ✅ **Database Architect - COMPLETE**

- [x] Schema design (3NF, all constraints)
- [x] Scientific validation (coefficients match literature)
- [x] Performance optimization (indexes, views)
- [x] Documentation & verification scripts
- [x] Team infrastructure (Docker, Make, CI/CD)

### 📋 **Data Engineer - TODO**

```bash
# Your main task: Complete etl/transform.ipynb
# Generate these 4 CSVs from the 6 downloaded XPT files:
# 1. users.csv (from DEMO_J.XPT)
# 2. sessions.csv (derived from exam dates)
# 3. measurements.csv (from BIOPRO_J, GLU_J, HSCRP_J, CBC_J)
# 4. anthropometry.csv (from BMX_J.XPT) ← Important for HD

# Then run: make etl
```

### 📋 **Backend Lead - TODO**

```bash
# Replace API stubs with real database queries in src/api/main.py
# Key endpoints to implement:
# - GET /users/{id}/phenotypic-age
# - GET /users/{id}/hd-score
# - POST /users/{id}/measurements
# - GET /users/{id}/biomarker-trends

# Database connection ready at: mysql://biomarker_user:pass@localhost:3307/longevity
```

### 📋 **UI Lead - TODO**

```bash
# Extend src/ui/app.py with:
# - Biomarker visualization (trends, reference ranges)
# - Biological age display (both models)
# - User input forms for new measurements
# - Population comparison charts

# HD calculator ready in src/analytics/hd.py
```

---

## 7 · Development tools & services

### 🗄️ **Database Access**

- **Adminer GUI:** [http://localhost:8080](http://localhost:8080)
  - Server: `db` | User: `biomarker_user` | Pass: `biomarker_pass` | DB: `longevity`
- **Command line:** `mysql -h localhost -P 3307 -u biomarker_user -pbiomarker_pass longevity`

### 🔧 **Service URLs**

- **API:** [http://localhost:8000](http://localhost:8000) (with hot reload)
- **API Docs:** [http://localhost:8000/docs](http://localhost:8000/docs) (Swagger UI)
- **Dashboard:** [http://localhost:80](http://localhost:80) (HTTP server)

### 📝 **Code Quality**

- **Pre-commit hooks:** Auto-run black, flake8, trailing whitespace
- **SQLFluff:** Available but commented (parsing issues with complex DDL) - see `docs/sqlfluff_status.md`
- **CI/CD:** All checks must pass before merge

---

## 8 · FAQ & troubleshooting

<details><summary><strong>Port conflicts (3307/8000/8501 already in use)?</strong></summary>

Edit `.env` file and change:

```bash
MYSQL_PORT=3308        # Change from 3307
APP_API_PORT=8001      # Change from 8000
```

For the HTTP server, edit the `make ui` target in `Makefile`:

```bash
ui:
	$(VENV_ACTIVATE) cd src/ui && python -m http.server 8502
```

</details>

<details><summary><strong>Virtual environment issues?</strong></summary>

```bash
# Nuclear reset
rm -rf .venv
make install    # Rebuilds everything

# Manual setup if needed
python3.11 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt -r requirements-dev.txt
pre-commit install
```

</details>

<details><summary><strong>Database connection errors?</strong></summary>

```bash
# Check Docker status
docker ps                    # Should see longevity_db running
docker logs longevity_db     # Check for startup errors

# Reset database completely
make clean
make db
sleep 10     # Wait for full startup
make db-reset
```

</details>

<details><summary><strong>Tests failing?</strong></summary>

```bash
# Ensure database is running and loaded
make db
make db-reset

# Run verification script
python verify_db_setup.py   # Should pass all checks

# Run tests with verbose output
pytest tests/ -v

# Check CI logs on GitHub for environment-specific issues
```

</details>

<details><summary><strong>SQLFluff integration?</strong></summary>

SQLFluff is available but has parsing issues with our complex MySQL DDL (multi-line DROP statements, etc.).

**Current status:** Commented out in pre-commit, can be used manually for simpler SQL files.

See `docs/sqlfluff_status.md` for details and workarounds.

</details>

<details><summary><strong>How to add new Python dependencies?</strong></summary>

1. Add to `requirements.txt` (pin exact version)
2. `pip install -r requirements.txt`
3. `pre-commit run --all-files` (ensure still green)
4. Push PR - CI will verify in fresh environment
</details>

<details><summary><strong>Which demo user should I use for testing?</strong></summary>

**Quick reference:**

- **User 101:** All optimal values, perfect for "happy path" testing
- **User 103:** 3 sessions of data, use for trend analysis (Q5, Q6, Q7)
- **User 102:** Multiple abnormal values, good for edge cases
- **See full persona table in query implementation guide**

All demo users have UserIDs 101-106, SEQN 100001-100006.

</details>

<details><summary><strong>Why does my query return empty results?</strong></summary>

Most likely you forgot to load demo data:

```bash
make seed-demo
make verify-demo-data  # Should show 6 users

---

## 9 · Scientific references

### 📚 **Biological Age Models**
- **Phenotypic Age:** Levine et al. (2018) - [PMID: 29676998](https://pubmed.ncbi.nlm.nih.gov/29676998/)
- **Homeostatic Dysregulation:**
  - Cohen et al. (2013) - [PMID: 23376244](https://pubmed.ncbi.nlm.nih.gov/23376244/)
  - Belsky et al. (2015) - [PMID: 26150497](https://pubmed.ncbi.nlm.nih.gov/26150497/) • [PMC4522793](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4522793/)

### 🧪 **Data Source**
- **NHANES 2017-2018:** [CDC National Health and Nutrition Examination Survey](https://www.cdc.gov/nchs/nhanes/index.html)

---

*Last updated: May 14, 2025 | Schema v1.3 | Team Guide v1.0*
```
