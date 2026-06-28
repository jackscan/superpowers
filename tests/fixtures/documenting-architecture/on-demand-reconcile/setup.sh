#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="${1:-/tmp/da-ondemand}"

rm -rf "$WORK" && mkdir -p "$WORK"
cd "$WORK"
git init -q
git config user.email "test@test"
git config user.name "test"

# First commit: the before state
mkdir -p docs
cp "$HERE/before/architecture.md" docs/architecture.md
git add -A && git commit -qm "initial"

OLD_HASH=$(git rev-parse HEAD)
# Rewrite the marker to point at this commit
sed -i "s/OLDER/$OLD_HASH/" docs/architecture.md
git add -A && git commit -qm "set marker"

# Second commit: add a Worker component (a real architectural change)
mkdir -p src/worker
echo 'def run(): pass' > src/worker/worker.py
git add -A && git commit -qm "feat: add background worker component"

# Third commit: trivial change (typo fix in a README)
echo "# Demo" > README.md
git add -A && git commit -qm "docs: add readme"

echo "Setup complete at $WORK"
echo "HEAD=$(git rev-parse HEAD)"
echo "MARKER=$OLD_HASH"
