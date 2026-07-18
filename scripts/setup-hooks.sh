#!/usr/bin/env bash
# Installs the repo's git hooks by pointing git at the tracked hooks/ directory.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
git config core.hooksPath hooks
chmod +x hooks/* 2>/dev/null || true
echo "Installed git hooks (core.hooksPath=hooks):"
echo "  - pre-commit: regenerates docs/ gallery when a watch face changes"
echo "  - pre-push:   runs build + lint + WFF validation"
