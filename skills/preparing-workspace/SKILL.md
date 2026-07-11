---
name: preparing-workspace
description: Use when starting feature work or before executing an implementation plan
---

# Preparing Workspace

## Overview

Before starting new work, verify the workspace is clean and tests pass at baseline. This catches pre-existing failures early so you can distinguish them from bugs you introduce.

**Core principle:** Clean tree → baseline tests → ready to implement.

**Announce at start:** "I'm using the preparing-workspace skill to verify the workspace before starting work."

## Step 1: Check for Clean Workspace

Run:

```bash
git status --porcelain
```

**If output is empty:** Workspace is clean. Skip to Step 2.

**If any output:** The workspace has uncommitted or untracked changes. Present these options:

1. **Commit** — stage and commit the pending changes. Ask the user for a commit message.
2. **Stash** — run `git stash push -u` (includes untracked files).
3. **Discard** — run `git checkout -- . && git clean -fd`. This is destructive; require the user to type `discard` to confirm.
4. **Abort** — stop. Do not start new work.

After the user chooses and the action runs, re-run `git status --porcelain` to verify the workspace is now clean. If still dirty (e.g. commit failed), report and stop.

## Step 2: Run Baseline Tests

Run the project's test suite (e.g. `npm test`, `cargo test`, `pytest`, `go test ./...`) to confirm the workspace starts clean.

**No tests found:** Skip. Report "No test suite detected."

**If tests fail:** Report the failures and ask whether to proceed or investigate. Do not assume baseline is green. Do not proceed without explicit consent.

**If tests pass:** Report:

```
Workspace clean, <N> tests passing.
Ready to implement <feature-name>.
```

## Quick Reference

| Situation | Action |
|-----------|--------|
| Clean workspace | Skip to baseline tests |
| Dirty workspace | Present 4 options (commit/stash/discard/abort) |
| Discard chosen | Require typed `discard` confirmation |
| After commit/stash/discard | Re-verify clean before proceeding |
| No test suite detected | Skip tests, report ready |
| Baseline tests fail | Report failures, ask before proceeding |
| Baseline tests pass | Report ready |

## Common Mistakes

### Proceeding with a dirty workspace
- **Problem:** Can't tell your changes from pre-existing ones
- **Fix:** Resolve (commit/stash/discard) or abort before starting

### Proceeding with failing baseline tests
- **Problem:** Can't distinguish new bugs from pre-existing issues
- **Fix:** Report failures, get explicit permission to proceed

### Discarding without confirmation
- **Problem:** Permanently destroys uncommitted work
- **Fix:** Require typed `discard` confirmation

### Skipping re-verify after commit/stash/discard
- **Problem:** Action may have failed silently
- **Fix:** Always re-run `git status --porcelain` after the action

## Red Flags

**Never:**
- Discard without typed confirmation
- Assume tests pass without running them
- Create a worktree or branch (this skill does not do that)
- Install dependencies (they are already in-place)

**Always:**
- Run `git status --porcelain` first
- Re-verify clean after any dirty-workspace action
- Run baseline tests and verify output
- Get explicit consent before proceeding with failing tests
