#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="${1:-/tmp/da-stale}"

rm -rf "$WORK" && mkdir -p "$WORK/docs"
cd "$WORK"
git init -q
git config user.email "test@test"
git config user.name "test"

cp "$HERE/before/architecture.md" docs/architecture.md
git add -A && git commit -qm "initial"
OLD_HASH=$(git rev-parse HEAD)
sed -i "s/OLDER/$OLD_HASH/" docs/architecture.md
git add -A && git commit -qm "set marker"

# Three commits since marker (set marker + change 1 + change 2) -> stale by 3
echo "x" >> README.md && git add -A && git commit -qm "change 1"
echo "y" >> README.md && git add -A && git commit -qm "change 2"

echo "Setup complete at $WORK"
echo "HEAD=$(git rev-parse HEAD)"
echo "MARKER=$OLD_HASH"
