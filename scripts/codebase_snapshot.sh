#!/bin/bash
# create_snapshot.sh - Creates a snapshot of the codebase while excluding large files

OUTPUT_FILE="codebase_snapshot.txt"

# Clear output file if it exists
> "$OUTPUT_FILE"

# Write header
echo "==================================================" >> "$OUTPUT_FILE"
echo "  LONGEVITY BIOMARKER TRACKER CODEBASE SNAPSHOT   " >> "$OUTPUT_FILE"
echo "  Created on: $(date)                             " >> "$OUTPUT_FILE"
echo "==================================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Function to write file contents to snapshot
write_file() {
  local file="$1"
  echo "==================================================" >> "$OUTPUT_FILE"
  echo "FILE: $file" >> "$OUTPUT_FILE"
  echo "==================================================" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
  cat "$file" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
}

# List of patterns to exclude
EXCLUDE_PATTERNS=(
  # Data files
  "data/raw/*"
  "data/clean/*"

  # Database dumps
  "*.dump"

  # Virtual environment
  "venv/*"

  # Build artifacts
  "build/*"
  "dist/*"
  "*.egg-info/*"

  # Node modules
  "node_modules/*"

  # Cache files
  "__pycache__/*"
  ".pytest_cache/*"
  ".ipynb_checkpoints/*"

  # Logs
  "*.log"

  # Large generated files
  "*.csv"
  "*.xpt"
  "*.parquet"
  "*.feather"
  "*.pickle"

  # IDE files
  ".idea/*"
  ".vscode/*"
)

# Create exclude options for find command
EXCLUDE_OPTIONS=""
for pattern in "${EXCLUDE_PATTERNS[@]}"; do
  EXCLUDE_OPTIONS="$EXCLUDE_OPTIONS -not -path \"*/$pattern\""
done

# Write summary of project structure
echo "PROJECT STRUCTURE:" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
find . -type d -not -path "*/\.*" -not -path "*/venv*" -not -path "*/node_modules*" | sort >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Allow specific SQL files (schema only, not data)
write_file "./sql/schema.sql"

# Snapshot all code and configuration files
# Using separate find commands instead of one big command with exclude options
# as that can be problematic with shell expansion
echo "Finding and processing files..."
find . -type f \( -name "*.py" -o -name "*.ipynb" -o -name "*.md" -o -name "*.sh" -o -name "*.yml" -o -name "*.yaml" -o -name "Makefile" -o -name "Dockerfile" -o -name "docker-compose.yml" -o -name ".env.example" -o -name "*.js" -o -name "*.html" -o -name "*.css" \) \
  -not -path "*/.venv/*" \
  -not -path "*/.git/*" \
  -not -path "*/node_modules/*" \
  -not -path "*/__pycache__/*" \
  -not -path "*/.pytest_cache/*" \
  -not -path "*/.ipynb_checkpoints/*" \
  -not -path "*/data/raw/*" \
  -not -path "*/data/clean/*" \
  -not -path "*/build/*" \
  -not -path "*/dist/*" \
  -not -path "*/*.egg-info/*" \
  -not -path "*/.idea/*" \
  -not -path "*/.vscode/*" \
  | sort | while read -r file; do
    # Skip large files (> 100KB)
    file_size=$(wc -c < "$file")
    if [ "$file_size" -gt 102400 ]; then
      echo "Skipping large file: $file ($file_size bytes)" >> "$OUTPUT_FILE"
    else
      # For notebooks, only include metadata and code, not outputs
      if [[ "$file" == *.ipynb ]]; then
        echo "==================================================" >> "$OUTPUT_FILE"
        echo "FILE: $file (code cells only, outputs excluded)" >> "$OUTPUT_FILE"
        echo "==================================================" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        if command -v jq >/dev/null 2>&1; then
          jq 'del(.cells[].outputs) | del(.cells[].execution_count)' "$file" >> "$OUTPUT_FILE"
        else
          echo "[WARN] jq not found – skipping notebook sanitisation" >> "$OUTPUT_FILE"
        fi

      else
        write_file "$file"
      fi
    fi
  done

# Write file count statistics
echo "==================================================" >> "$OUTPUT_FILE"
echo "FILE COUNT STATISTICS:" >> "$OUTPUT_FILE"
echo "==================================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "Python files: $(find . -name "*.py" -not -path "*/venv/*" -not -path "*/\.*" | wc -l)" >> "$OUTPUT_FILE"
echo "Jupyter notebooks: $(find . -name "*.ipynb" -not -path "*/venv/*" -not -path "*/\.*" -not -path "*/.ipynb_checkpoints/*" | wc -l)" >> "$OUTPUT_FILE"
echo "Shell scripts: $(find . -name "*.sh" -not -path "*/venv/*" -not -path "*/\.*" | wc -l)" >> "$OUTPUT_FILE"
echo "Markdown/Documentation: $(find . -name "*.md" -not -path "*/venv/*" -not -path "*/\.*" | wc -l)" >> "$OUTPUT_FILE"
echo "YAML/Configuration: $(find . -name "*.yml" -o -name "*.yaml" -not -path "*/venv/*" -not -path "*/\.*" | wc -l)" >> "$OUTPUT_FILE"
echo "JavaScript files: $(find . -name "*.js" -not -path "*/venv/*" -not -path "*/node_modules/*" -not -path "*/\.*" | wc -l)" >> "$OUTPUT_FILE"
echo "HTML files: $(find . -name "*.html" -not -path "*/venv/*" -not -path "*/node_modules/*" -not -path "*/\.*" | wc -l)" >> "$OUTPUT_FILE"
echo "CSS files: $(find . -name "*.css" -not -path "*/venv/*" -not -path "*/node_modules/*" -not -path "*/\.*" | wc -l)" >> "$OUTPUT_FILE"

echo "Snapshot created: $OUTPUT_FILE"
