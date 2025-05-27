# Longevity Biomarker Tracking System

[![CI](https://github.com/randaldrew/longevity-biomarker-tracker/actions/workflows/ci.yml/badge.svg)](https://github.com/randaldrew/longevity-biomarker-tracker/actions/workflows/ci.yml)

Database system for tracking biomarkers and calculating biological age based on NHANES data.

## Quick Start

```bash
### First-time setup (Mac/Linux)

```bash
git clone … && cd longevity-biomarker-tracker
cp .env.example .env
make install          # python deps + pre-commit
make db               # starts MySQL + Adminer on :3307
make run              # FastAPI on :8000
make ui               # Do this in a new terminal. Then open http://localhost:80
# ETL is optional until the transform notebook is finished
```

## Database Schema Updates

The initial database schema is loaded automatically when the database container is first created. For subsequent schema changes:

1. Update the `sql/schema.sql` file
2. Run the following command to apply changes:
   ```bash
   docker compose exec db mysql -u biomarker_user -pbiomarker_pass longevity < sql/schema.sql
   ```
3. Or use this shortcut ```make db-reset```

## Notes

- The ETL process (`make etl`) will generate a `tests/sample_dump.sql` file with sample data for testing purposes.
- This sample data is used by the CI workflow to test the API functionality.

## Development Workflow

### Pre-commit Hooks

This project uses pre-commit hooks to ensure code quality and consistency. To set up:

```bash
# Install pre-commit
make install  # or manually: pip install pre-commit

# Install the git hooks
pre-commit install
```
