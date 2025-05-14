.PHONY: db etl test run ui clean help db-reset

# Use one shell for multi-line recipes
.ONESHELL:

# Load environment variables from .env file (robust approach)
ifneq ("$(wildcard .env)","")
include .env
export $(shell grep -E '^[A-Za-z_][A-Za-z0-9_]*=' .env | cut -d= -f1)
endif

# Allow database name override (useful for tests)
DB ?= $(MYSQL_DATABASE)

help:
	@echo "Longevity Biomarker Tracker"
	@echo ""
	@echo "make db       - Start MySQL database"
	@echo "make etl      - Run ETL process (download, transform, load)"
	@echo "make test     - Run tests"
	@echo "make run      - Start API server"
	@echo "make ui       - Start UI dashboard"
	@echo "make clean    - Remove all data and containers"

install:
	pip install -r requirements.txt
	pre-commit install

db:
	docker compose up -d db adminer

etl:
	python etl/download_nhanes.py
	@if [ -f etl/transform.ipynb ] && [ -s etl/transform.ipynb ]; then \
		jupyter nbconvert --execute etl/transform.ipynb --to notebook --inplace || echo "[WARN] Failed to execute transform.ipynb - continuing anyway"; \
	else \
		echo "[WARN] transform.ipynb not found or empty — skipping transform step"; \
	fi
	bash etl/load.sh

test:
	pytest tests/

run:                           # start FastAPI with hot-reload
	# use env vars if they exist, else fall back to 127.0.0.1:8000
	cd src/api && \
		uvicorn main:app --reload \
		--host $${APP_API_HOST:-127.0.0.1} \
		--port $${APP_API_PORT:-8000}




ui:
	cd src/ui && streamlit run app.py

clean:
	docker compose down -v
	rm -rf data/raw/* data/clean/*

db-reset:
	docker compose exec -T db mysql -u$(MYSQL_USER) -p"$(MYSQL_PASSWORD)" $(DB) < sql/schema.sql
	docker compose exec -T db mysql -u$(MYSQL_USER) -p"$(MYSQL_PASSWORD)" $(DB) < sql/01_seed.sql
