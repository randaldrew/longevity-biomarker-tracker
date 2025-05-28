#!/usr/bin/env bash
# ------------------------------------------------------------------
# codebase_snapshot.sh – Create a human-readable, self-contained
# snapshot of the Longevity Biomarker Tracker repo.
#
#  • Default (dev) mode: skips files >100 KB to stay fast/light.
#  • Release mode:  SNAPSHOT_MODE=release  → no size cap.
#
# Output: codebase_snapshot.txt (or $OUTPUT_FILE if set)
# ------------------------------------------------------------------

set -euo pipefail

# ── Change to repo root regardless of where script is called from ──
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# ── Config ─────────────────────────────────────────────────────────
OUTPUT_FILE="${OUTPUT_FILE:-codebase_snapshot.txt}"
MAX_BYTES=102400           # 100 KB size cap (dev)
if [[ "${SNAPSHOT_MODE-}" == "release" ]]; then
  echo "➡  Snapshot running in RELEASE mode – no file-size cap"
  MAX_BYTES=999999999
fi

# ── Helpers ────────────────────────────────────────────────────────
write_header() {
  printf "==================================================\n"          >> "$OUTPUT_FILE"
  printf "  LONGEVITY BIOMARKER TRACKER CODEBASE SNAPSHOT   \n"         >> "$OUTPUT_FILE"
  printf "  Created on: %s                             \n" "$(date)"    >> "$OUTPUT_FILE"
  printf "==================================================\n\n"        >> "$OUTPUT_FILE"
}

write_file() {
  local file="$1"
  printf "==================================================\n"         >> "$OUTPUT_FILE"
  printf "FILE: %s\n" "$file"                                         >> "$OUTPUT_FILE"
  printf "==================================================\n\n"       >> "$OUTPUT_FILE"
  cat "$file"                                                        >> "$OUTPUT_FILE"
  printf "\n\n"                                                      >> "$OUTPUT_FILE"
}

sanitise_ipynb() {
  local nb="$1"
  printf "==================================================\n"         >> "$OUTPUT_FILE"
  printf "FILE: %s (code cells only, outputs excluded)\n" "$nb"        >> "$OUTPUT_FILE"
  printf "==================================================\n\n"       >> "$OUTPUT_FILE"
  if command -v jq >/dev/null 2>&1; then
    jq 'del(.cells[].outputs) | del(.cells[].execution_count)' "$nb"  >> "$OUTPUT_FILE"
  else
    printf "[WARN] jq not found – raw notebook omitted]\n"            >> "$OUTPUT_FILE"
  fi
  printf "\n\n"                                                      >> "$OUTPUT_FILE"
}

# ── Start fresh ────────────────────────────────────────────────────
: > "$OUTPUT_FILE"
write_header

# ── Directory tree ────────────────────────────────────────────────
printf "PROJECT STRUCTURE:\n\n" >> "$OUTPUT_FILE"
find . -type d \
  -not -path "*/.*" -not -path "*/.venv*" -not -path "*/node_modules*" \
  | sort >> "$OUTPUT_FILE"
printf "\n" >> "$OUTPUT_FILE"

# Always include the schema first (easy to find)
if [[ -f "./sql/schema.sql" ]]; then
  write_file "./sql/schema.sql"
fi

# ── Process other SQL files in sql directory (avoid huge dumps) ────
echo "🗃️  Processing SQL files in sql/ directory..."
if [[ -d "./sql" ]]; then
  find ./sql -name "*.sql" -type f | grep -v schema.sql | while read -r sqlfile; do
    if [[ ! -f "$sqlfile" ]]; then
      continue
    fi

    # Skip likely dump files based on name patterns
    basename_lower=$(basename "$sqlfile" | tr '[:upper:]' '[:lower:]')
    if [[ "$basename_lower" == *"dump"* ]] || [[ "$basename_lower" == *"backup"* ]] ||
       [[ "$basename_lower" == *"export"* ]] || [[ "$basename_lower" == *"full"* ]]; then
      echo "   ⏭️  Skipping likely dump file: $sqlfile"
      printf "Skipped SQL dump file: %s (likely contains large dataset)\n" "$sqlfile" >> "$OUTPUT_FILE"
      continue
    fi

    file_size=$(wc -c < "$sqlfile" 2>/dev/null || echo "0")
    if [ "$file_size" -gt "$MAX_BYTES" ]; then
      echo "   ⏭️  Skipping large SQL file: $sqlfile ($file_size bytes)"
      printf "Skipping large SQL file: %s (%s bytes)\n" "$sqlfile" "$file_size" >> "$OUTPUT_FILE"
    else
      echo "   📄 Processing SQL: $sqlfile ($file_size bytes)"
      write_file "$sqlfile"
    fi
  done
fi

# ── Explicitly capture UI files from src/ui ───────────────────────
if [[ -d "./src/ui" ]]; then
  echo "📂 Processing UI files in src/ui..."
  find ./src/ui -name "*.html" -o -name "*.js" -o -name "*.css" | while read -r uifile; do
    if [[ -f "$uifile" ]]; then
      file_size=$(wc -c < "$uifile" 2>/dev/null || echo "0")
      if [ "$file_size" -le "$MAX_BYTES" ]; then
        echo "   📄 Processing UI: $uifile ($file_size bytes)"
        write_file "$uifile"
      else
        echo "   ⏭️  Skipping large UI file: $uifile ($file_size bytes)"
      fi
    fi
  done
fi

# ── File selection (original logic) ───────────────────────────────
find . -type f \( -name "*.py" -o -name "*.ipynb" -o -name "*.md" \
                 -o -name "*.sh" -o -name "*.yml" -o -name "*.yaml" \
                 -o -name "Makefile" -o -name "Dockerfile" \
                 -o -name "docker-compose.yml" -o -name ".env.example" \
                 -o -name "*.js" -o -name "*.html" -o -name "*.css" \) \
  -not -path "*/.git/*" -not -path "*/.venv/*" -not -path "*/node_modules/*" \
  -not -path "*/__pycache__/*" -not -path "*/.pytest_cache/*" \
  -not -path "*/.ipynb_checkpoints/*" \
  -not -path "*/data/raw/*" -not -path "*/data/clean/*" \
  -not -path "*/build/*" -not -path "*/dist/*" -not -path "*/*.egg-info/*" \
  -not -path "*/src/ui/*" \
  | sort | while read -r file; do
      file_size=$(wc -c < "$file")
      if [ "$file_size" -gt "$MAX_BYTES" ]; then
        printf "Skipping large file: %s (%s bytes)\n" "$file" "$file_size" >> "$OUTPUT_FILE"
        continue
      fi

      case "$file" in
        *.ipynb) sanitise_ipynb "$file" ;;
        *)       write_file     "$file" ;;
      esac
  done

# ── File-count stats ───────────────────────────────────────────────
printf "==================================================\n"          >> "$OUTPUT_FILE"
printf "FILE COUNT STATISTICS:\n"                                     >> "$OUTPUT_FILE"
printf "==================================================\n\n"        >> "$OUTPUT_FILE"

count() { find . -name "$1" -not -path "*/.venv/*" -not -path "*/.*" -not -path "*/node_modules/*" | wc -l; }
printf "Python files:              %5s\n" "$(count '*.py')"          >> "$OUTPUT_FILE"
printf "Jupyter notebooks:         %5s\n" "$(count '*.ipynb')"        >> "$OUTPUT_FILE"
printf "Shell scripts:             %5s\n" "$(count '*.sh')"           >> "$OUTPUT_FILE"
printf "SQL files:                 %5s\n" "$(count '*.sql')"          >> "$OUTPUT_FILE"
printf "Markdown/Documentation:    %5s\n" "$(count '*.md')"           >> "$OUTPUT_FILE"
printf "YAML/Configuration:        %5s\n" "$(count '*.y*ml')"         >> "$OUTPUT_FILE"
printf "JavaScript files:          %5s\n" "$(count '*.js')"           >> "$OUTPUT_FILE"
printf "HTML files:                %5s\n" "$(count '*.html')"         >> "$OUTPUT_FILE"
printf "CSS files:                 %5s\n" "$(count '*.css')"          >> "$OUTPUT_FILE"

echo ""
echo "✅ Snapshot created: $OUTPUT_FILE"
echo "📊 UI files found: $(count '*.html') HTML, $(count '*.js') JS, $(count '*.css') CSS"
echo "🗃️  SQL files found: $(count '*.sql') total"
