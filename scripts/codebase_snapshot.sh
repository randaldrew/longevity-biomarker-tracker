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
write_file "./sql/schema.sql"

# ── File selection ────────────────────────────────────────────────
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

count() { find . -name "$1" -not -path "*/.venv/*" -not -path "*/.*" | wc -l; }
printf "Python files:              %5s\n" "$(count '*.py')"          >> "$OUTPUT_FILE"
printf "Jupyter notebooks:         %5s\n" "$(count '*.ipynb')"        >> "$OUTPUT_FILE"
printf "Shell scripts:             %5s\n" "$(count '*.sh')"           >> "$OUTPUT_FILE"
printf "Markdown/Documentation:    %5s\n" "$(count '*.md')"           >> "$OUTPUT_FILE"
printf "YAML/Configuration:        %5s\n" "$(count '*.y*ml')"         >> "$OUTPUT_FILE"
printf "JavaScript files:          %5s\n" "$(count '*.js')"           >> "$OUTPUT_FILE"
printf "HTML files:                %5s\n" "$(count '*.html')"         >> "$OUTPUT_FILE"
printf "CSS files:                 %5s\n" "$(count '*.css')"          >> "$OUTPUT_FILE"

echo "Snapshot created: $OUTPUT_FILE"
