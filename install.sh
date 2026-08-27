#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/template"
TARGET="${1:-.}"

if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "Error: template directory not found at $TEMPLATE_DIR" >&2
  exit 1
fi

TARGET="$(cd "$TARGET" && pwd)"
echo "Installing AI Dev Team Shell into: $TARGET"

# Copy .cursor/ (agents + skills), merging without overwriting existing files
if [ -d "$TEMPLATE_DIR/.cursor" ]; then
  mkdir -p "$TARGET/.cursor"
  copied=0
  skipped=0
  while IFS= read -r -d '' file; do
    rel="${file#"$TEMPLATE_DIR/.cursor/"}"
    dest="$TARGET/.cursor/$rel"
    if [ -f "$dest" ]; then
      echo "  skip (exists): .cursor/$rel"
      skipped=$((skipped + 1))
    else
      mkdir -p "$(dirname "$dest")"
      cp "$file" "$dest"
      echo "  copy: .cursor/$rel"
      copied=$((copied + 1))
    fi
  done < <(find "$TEMPLATE_DIR/.cursor" -type f -print0)
  echo "  .cursor/: $copied copied, $skipped skipped"
fi

# Copy agent-outputs/ scaffold (file bus only; no fake src/ or tests/)
if [ -d "$TEMPLATE_DIR/agent-outputs" ]; then
  copied=0
  skipped=0
  while IFS= read -r -d '' file; do
    rel="${file#"$TEMPLATE_DIR/agent-outputs/"}"
    dest="$TARGET/agent-outputs/$rel"
    if [ -f "$dest" ]; then
      echo "  skip (exists): agent-outputs/$rel"
      skipped=$((skipped + 1))
    else
      mkdir -p "$(dirname "$dest")"
      cp "$file" "$dest"
      echo "  copy: agent-outputs/$rel"
      copied=$((copied + 1))
    fi
  done < <(find "$TEMPLATE_DIR/agent-outputs" -type f -print0)
  echo "  agent-outputs/: $copied copied, $skipped skipped"
fi

echo ""
echo "Installation complete."
echo ""
echo "Installed:"
echo "  .cursor/agents/ + .cursor/skills/  (required at repo root)"
echo "  agent-outputs/pipeline/            (specs + contracts + reviews)"
echo ""
echo "Agents: planner, designer, backend, frontend, tester, reviewer"
echo "Note: No src/ or tests/ folders are created."
echo "      Specialists write into your project's real layout."
echo ""
echo "Next steps:"
echo "  1. Open your project in Cursor"
echo "  2. Run: /plan Add user login portal"
echo ""
echo "Individual phases:"
echo "  /implement  — run assigned specialists (requires Work Assignment in spec.md)"
echo "  /test       — run Tester (requires implementation files from the specs)"
echo "  /review     — run Reviewer (requires specs + implementation + tests)"
