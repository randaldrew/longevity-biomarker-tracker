#!/usr/bin/env bash
# Bootstrap script for Longevity Biomarker Tracker
set -e

cd "$(dirname "$0")/.."          # ALWAYS work from repo root

PY=${PYTHON:-python3.11}
VENV=".venv"

echo "🧬 Setting up Longevity Biomarker Tracker environment in $(pwd)"

# Check for system Graphviz
echo "▶  Checking for Graphviz..."
if command -v dot &> /dev/null; then
    echo "✓ Graphviz found: $(dot -V 2>&1)"
    GRAPHVIZ_AVAILABLE=true
else
    echo "⚠️  Graphviz not found. Install with: brew install graphviz"
    GRAPHVIZ_AVAILABLE=false
fi

echo "▶  Creating virtual env in $VENV with $PY"
$PY -m venv "$VENV"

echo "▶  Activating & upgrading pip"
source "$VENV/bin/activate"
pip install --upgrade pip wheel

echo "▶  Installing runtime dependencies"
pip install -r requirements.txt

echo "▶  Installing development dependencies"
pip install -r requirements-dev.txt

# Install Python graphviz wrapper separately (avoids pygraphviz issues)
if [ "$GRAPHVIZ_AVAILABLE" = true ]; then
    echo "▶  Installing Python graphviz wrapper..."
    pip install graphviz>=0.20.0
    echo "✓ Python graphviz wrapper installed"
else
    echo "⚠️  Skipping Python graphviz wrapper (system Graphviz not found)"
fi

echo "▶  Setting up pre-commit hooks"
pre-commit install

echo "✅  Setup complete! Activate with:"
echo "   source $VENV/bin/activate"
echo ""
echo "🚀 Quick start:"
echo "   make db     # Start MySQL + Adminer"
echo "   make run    # Start FastAPI (in another terminal)"
echo "   make ui     # Start HTTP server for UI (in another terminal)"
