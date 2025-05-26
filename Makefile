.PHONY: db etl test run ui clean help db-reset venv install install-dev install-prod lint reference-ranges

# Use one shell for multi-line recipes
.ONESHELL:

# Load environment variables from .env file (robust approach)
ifneq ("$(wildcard .env)","")
include .env
export $(shell grep -E '^[A-Za-z_][A-Za-z0-9_]*=' .env | cut -d= -f1)
endif

# Virtual environment detection
ifneq ("$(wildcard .venv/bin/activate)","")
	VENV_ACTIVATE = source .venv/bin/activate &&
else
	VENV_ACTIVATE =
endif

# Allow database name override (useful for tests)
DB ?= $(MYSQL_DATABASE)

help:
	@echo "Longevity Biomarker Tracker"
	@echo ""
	@echo "Setup commands:"
	@echo "  make venv        - Create .venv virtual environment"
	@echo "  make install     - Full setup (venv + dependencies + hooks)"
	@echo "  make install-dev - Install dev dependencies only"
	@echo "  make install-prod- Install production dependencies only"
	@echo ""
	@echo "Development commands:"
	@echo "  make db          - Start MySQL database"
	@echo "  make etl         - Run ETL process (download, transform, load + reference ranges)"
	@echo "  make reference-ranges - Generate reference range data only"
	@echo "  make test        - Run tests"
	@echo "  make run         - Start API server"
	@echo "  make ui          - Start UI dashboard"
	@echo "  make lint        - Run code formatting and linting"
	@echo ""
	@echo "Cleanup commands:"
	@echo "  make clean       - Remove all data and containers"
	@echo "  make db-reset    - Reset database with fresh schema/seeds"

# Virtual environment setup
venv:
	@if [ ! -d ".venv" ]; then \
		echo "Creating virtual environment..."; \
		bash scripts/bootstrap_venv.sh; \
	else \
		echo "Virtual environment already exists at .venv"; \
		echo "To recreate, run: rm -rf .venv && make venv"; \
	fi

# Full setup (recommended for new contributors)
install: venv
	@echo "✅ Setup complete! Activate with: source .venv/bin/activate"

# Install development dependencies (assumes venv exists)
install-dev:
	$(VENV_ACTIVATE) pip install -r requirements.txt -r requirements-dev.txt
	$(VENV_ACTIVATE) pre-commit install

# Install production dependencies only
install-prod:
	$(VENV_ACTIVATE) pip install -r requirements.txt

# Database operations
db:
	docker compose up -d db adminer

db-reset:
	docker compose exec -T db mysql -u$(MYSQL_USER) -p"$(MYSQL_PASSWORD)" $(DB) < sql/schema.sql
	docker compose exec -T db mysql -u$(MYSQL_USER) -p"$(MYSQL_PASSWORD)" $(DB) < sql/01_seed.sql

# Load demo users for testing/demo
seed-demo:
	docker compose exec -T db mysql -u$(MYSQL_USER) -p"$(MYSQL_PASSWORD)" $(MYSQL_DATABASE) < sql/demo_users.sql
	@echo "✅ Demo users loaded successfully"

# Verify demo data loaded correctly
verify-demo-data:
	docker compose exec -T db mysql -u$(MYSQL_USER) -p"$(MYSQL_PASSWORD)" $(MYSQL_DATABASE) -e \
		"SELECT u.UserID, u.SEQN, COUNT(DISTINCT s.SessionID) as Sessions, COUNT(DISTINCT m.BiomarkerID) as Biomarkers FROM User u LEFT JOIN MeasurementSession s ON u.UserID = s.UserID LEFT JOIN Measurement m ON s.SessionID = m.SessionID WHERE u.SEQN BETWEEN 9900001 AND 9900006 GROUP BY u.UserID, u.SEQN ORDER BY u.UserID;"

# Generate reference ranges (standalone)
reference-ranges:
	@mkdir -p data/clean
	$(VENV_ACTIVATE) python etl/generate_reference_ranges.py
	@echo "✅ Reference ranges generated successfully"

# ETL pipeline
etl:
	$(VENV_ACTIVATE) python etl/download_nhanes.py
	@if [ -f etl/transform.ipynb ] && [ -s etl/transform.ipynb ]; then \
		$(VENV_ACTIVATE) jupyter nbconvert --execute etl/transform.ipynb --to notebook --inplace || echo "[WARN] Failed to execute transform.ipynb - continuing anyway"; \
	else \
		echo "[WARN] transform.ipynb not found or empty — skipping transform step"; \
	fi
	$(VENV_ACTIVATE) python etl/generate_reference_ranges.py
	bash etl/load.sh

# Testing
test:
	$(VENV_ACTIVATE) pytest tests/

# Code quality
lint:
	$(VENV_ACTIVATE) pre-commit run --all-files

# Application services
run:  # start FastAPI with hot-reload
	$(VENV_ACTIVATE) cd src/api && \
		uvicorn main:app --reload \
		--host $${APP_API_HOST:-127.0.0.1} \
		--port $${APP_API_PORT:-8000}

ui:
	$(VENV_ACTIVATE) cd src/ui && streamlit run app.py

# Cleanup
clean:
	docker compose down -v
	rm -rf data/raw/* data/clean/*

# Clean everything including venv (nuclear option)
clean-all: clean
	rm -rf .venv
	rm -rf __pycache__ src/__pycache__ src/*/__pycache__
	rm -rf .pytest_cache
