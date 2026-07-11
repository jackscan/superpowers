---
name: finishing-work
description: Use when implementation is complete and all tasks are done
---

# Finishing Work

## Overview

After implementation is complete, run final checks, sync spec deltas, and verify all changes are committed before declaring work done.

**Core principle:** Checks pass → specs synced → tree clean → work complete.

**Announce at start:** "I'm using the finishing-work skill to run final checks before declaring work complete."

## Step 1: Run Final Checks

Run the project's checks — tests plus any lint, typecheck, or build checks the project defines (e.g. `npm test`, `cargo test`, `pytest`, `go test ./...`).

**If the project has no checks:** Skip and continue to Step 2.

**If any check fails:** Report the failures and stop. Do not declare work complete.

**If all checks pass:** Continue to Step 2.

## Step 2: Sync Spec Deltas

Check for delta specs:

```bash
git rev-parse --abbrev-ref HEAD
```

Use the branch name as `<feature>`. List `docs/specs/changes/<feature>/specs/*/spec.md`.

**If deltas exist:** Invoke the `superpowers:syncing-specs` skill to merge them into canonical specs and archive the deltas.

**If `docs/specs/` does not exist or no deltas are found:** Skip silently. This is a no-op unless the project has opted into living specs.

## Step 3: Verify Commit Completeness

Run:

```bash
git status --porcelain
```

**If any output:** The tree is dirty. Report exactly what is uncommitted or untracked. Ask the user to commit or stash before declaring work done. Do not proceed to "work complete" with a dirty tree.

**If output is empty:** All changes are committed. Continue.

## Step 4: Report Complete

```
All checks pass, specs synced, all changes committed.
Work complete.
```

## Quick Reference

| Situation | Action |
|-----------|--------|
| Any check fails | Report failures, stop |
| No checks defined | Skip, continue to Step 2 |
| Spec deltas exist | Invoke syncing-specs |
| No spec deltas | Skip spec sync silently |
| Dirty tree | Report, ask to commit/stash |
| Clean tree, all checks pass | Declare work complete |

## Common Mistakes

### Declaring work complete with failing checks
- **Problem:** Shipping broken code
- **Fix:** All detected checks must pass before Step 2

### Declaring work complete with uncommitted changes
- **Problem:** Work that isn't committed can be lost
- **Fix:** Verify `git status --porcelain` is empty before declaring done

### Skipping spec sync when deltas exist
- **Problem:** Canonical specs drift from actual behavior
- **Fix:** Check for deltas and invoke syncing-specs if found

### Running spec sync when no deltas exist
- **Problem:** Wastes time, may confuse
- **Fix:** Only invoke syncing-specs when `docs/specs/changes/<feature>/` has content

## Red Flags

**Never:**
- Declare "work complete" with failing tests, lint, or typecheck
- Declare "work complete" with a dirty tree
- Merge, push, create PRs, delete branches, or clean up worktrees (this skill does not do that)

**Always:**
- Run all project checks and verify output
- Check for spec deltas before declaring done
- Verify `git status --porcelain` is empty
