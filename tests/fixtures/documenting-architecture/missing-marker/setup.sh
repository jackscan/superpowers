#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="${1:-/tmp/da-missing-marker}"

rm -rf "$WORK" && mkdir -p "$WORK"
cd "$WORK"
git init -q
git config user.email "test@test"
git config user.name "test"

# First commit: the before state (deliberately NO last-reconciled marker)
mkdir -p docs
cp "$HERE/before/architecture.md" docs/architecture.md
git add -A && git commit -qm "initial"

# Second commit: add a Worker component (a real architectural change)
mkdir -p src/worker
echo 'def run(): pass' > src/worker/worker.py
git add -A && git commit -qm "feat: add background worker component"

# Third commit: trivial change (README)
echo "# Demo" > README.md
git add -A && git commit -qm "docs: add readme"

echo "Setup complete at $WORK"
echo "HEAD=$(git rev-parse HEAD)"
