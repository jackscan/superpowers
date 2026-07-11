# Simplify Workspace Skills Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove `dispatching-parallel-agents`, replace `using-git-worktrees` with `preparing-workspace`, and replace `finishing-a-development-branch` with `finishing-work`, updating all references.

**Architecture:** Two new skill files are created, four reference files are updated, and three old skill directories are deleted. All changes are markdown files — no code or tests to run.

**Tech Stack:** Markdown skill files, YAML frontmatter, shell commands for git/test detection.

## Global Constraints

- Skill names use letters, numbers, and hyphens only.
- YAML frontmatter `name` + `description` fields, max 1024 chars total.
- Descriptions start with "Use when..." and describe triggering conditions only, never workflow summary.
- No worktree creation, branch creation, merge, PR, or branch deletion logic in either new skill.
- No `npm install` / dependency install step.
- Spec sync is conditional on `docs/specs/changes/<feature>/` existing; no-op otherwise.
- Auto-detection of test/lint/typecheck commands must be conservative — only run commands the project actually defines.

---

### Task 1: Create `preparing-workspace` skill

**Files:**
- Create: `skills/preparing-workspace/SKILL.md`

**Interfaces:**
- Produces: a new skill `preparing-workspace` that other skills reference instead of `using-git-worktrees`

- [ ] **Step 1: Create the skill directory and file**

Create `skills/preparing-workspace/SKILL.md` with this exact content:

```markdown
---
name: preparing-workspace
description: Use when starting feature work or before executing an implementation plan - verifies the workspace is clean (no uncommitted or untracked changes) and the test suite passes at baseline
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

Auto-detect the test command:

| Project marker | Command |
|----------------|---------|
| `package.json` with `scripts.test` | `npm test` |
| `Cargo.toml` | `cargo test` |
| `pyproject.toml` or `requirements.txt` | `pytest` |
| `go.mod` | `go test ./...` |

**No recognized project file:** Skip silently. Report "No test suite detected."

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
```

- [ ] **Step 2: Verify the file was created correctly**

Run: `head -5 skills/preparing-workspace/SKILL.md`
Expected: YAML frontmatter with `name: preparing-workspace` and the description line.

Run: `wc -l skills/preparing-workspace/SKILL.md`
Expected: ~95-105 lines.

- [ ] **Step 3: Commit**

```bash
git add skills/preparing-workspace/SKILL.md
git commit -m "feat: add preparing-workspace skill

Replaces using-git-worktrees with a leaner skill that verifies
workspace cleanliness and baseline test pass without worktree
or branch creation."
```

---

### Task 2: Create `finishing-work` skill

**Files:**
- Create: `skills/finishing-work/SKILL.md`

**Interfaces:**
- Produces: a new skill `finishing-work` that other skills reference instead of `finishing-a-development-branch`
- Consumes: `superpowers:syncing-specs` (invoked conditionally when spec deltas exist)

- [ ] **Step 1: Create the skill directory and file**

Create `skills/finishing-work/SKILL.md` with this exact content:

```markdown
---
name: finishing-work
description: Use when implementation is complete and all tasks are done - runs final checks (tests, lint, typecheck), syncs spec deltas, and verifies all changes are committed
---

# Finishing Work

## Overview

After implementation is complete, run final checks, sync spec deltas, and verify all changes are committed before declaring work done.

**Core principle:** Checks pass → specs synced → tree clean → work complete.

**Announce at start:** "I'm using the finishing-work skill to run final checks before declaring work complete."

## Step 1: Run Final Checks

Auto-detect and run checks from the project:

### Tests

| Project marker | Command |
|----------------|---------|
| `package.json` with `scripts.test` | `npm test` |
| `Cargo.toml` | `cargo test` |
| `pyproject.toml` or `requirements.txt` | `pytest` |
| `go.mod` | `go test ./...` |

If no test runner is detected, skip silently.

### Lint

Run if any of these apply:

| Marker | Command |
|--------|---------|
| `package.json` with `scripts.lint` | `npm run lint` |
| `.eslintrc*` or `eslint.config.*` exists | `npx eslint .` |
| `ruff.toml` exists, or `pyproject.toml` contains `[tool.ruff]` | `ruff check` |
| `.golangci.yml` or `.golangci.yaml` exists | `golangci-lint run` |

### Typecheck

Run if any of these apply:

| Marker | Command |
|--------|---------|
| `package.json` with `scripts.typecheck` | `npm run typecheck` |
| `tsconfig.json` exists | `npx tsc --noEmit` |
| `mypy.ini` exists, or `pyproject.toml` contains `[tool.mypy]` | `mypy .` |

**If any check fails:** Report the failures and stop. Do not declare work complete.

**If all detected checks pass:** Continue to Step 2.

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
| Test/lint/typecheck fails | Report failures, stop |
| No test runner detected | Skip tests silently |
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
- Run all detected checks and verify output
- Check for spec deltas before declaring done
- Verify `git status --porcelain` is empty
```

- [ ] **Step 2: Verify the file was created correctly**

Run: `head -5 skills/finishing-work/SKILL.md`
Expected: YAML frontmatter with `name: finishing-work` and the description line.

Run: `wc -l skills/finishing-work/SKILL.md`
Expected: ~115-125 lines.

- [ ] **Step 3: Commit**

```bash
git add skills/finishing-work/SKILL.md
git commit -m "feat: add finishing-work skill

Replaces finishing-a-development-branch with a leaner skill that
runs final checks, syncs spec deltas, and verifies commit
completeness without merge/PR/branch-deletion logic."
```

---

### Task 3: Update references and delete old skills

**Files:**
- Modify: `README.md:50,60,79,82-83`
- Modify: `skills/executing-plans/SKILL.md:35-37,68,70`
- Modify: `skills/subagent-driven-development/SKILL.md:66,81,409,412`
- Modify: `skills/writing-plans/SKILL.md:16`
- Delete: `skills/using-git-worktrees/` (entire directory)
- Delete: `skills/finishing-a-development-branch/` (entire directory)
- Delete: `skills/dispatching-parallel-agents/` (entire directory)

**Interfaces:**
- Consumes: the two new skills from Tasks 1 and 2

- [ ] **Step 1: Update `README.md` workflow descriptions (lines 50 and 60)**

Change line 50 from:

```markdown
2. **using-git-worktrees** - Activates after design approval. Creates isolated workspace on new branch, runs project setup, verifies clean test baseline.
```

to:

```markdown
2. **preparing-workspace** - Activates before starting work. Verifies workspace is clean (no uncommitted or untracked changes) and test suite passes at baseline.
```

Change line 60 from:

```markdown
7. **finishing-a-development-branch** - Activates when tasks complete. Verifies tests, presents options (merge/PR/keep/discard), cleans up worktree.
```

to:

```markdown
7. **finishing-work** - Activates when tasks complete. Runs final checks (tests, lint, typecheck), syncs spec deltas, verifies all changes are committed.
```

- [ ] **Step 2: Update `README.md` skills listing (lines 79, 82-83)**

Remove line 79:

```markdown
- **dispatching-parallel-agents** - Concurrent subagent workflows
```

Change line 82 from:

```markdown
- **using-git-worktrees** - Parallel development branches
```

to:

```markdown
- **preparing-workspace** - Clean workspace and baseline test verification
```

Change line 83 from:

```markdown
- **finishing-a-development-branch** - Merge/PR decision workflow
```

to:

```markdown
- **finishing-work** - Final checks, spec sync, and commit completeness verification
```

- [ ] **Step 3: Update `skills/executing-plans/SKILL.md`**

Change lines 35-37 from:

```markdown
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch
- Follow that skill to verify tests, present options, execute choice
```

to:

```markdown
- Announce: "I'm using the finishing-work skill to complete this work."
- **REQUIRED SUB-SKILL:** Use superpowers:finishing-work
- Follow that skill to run final checks, sync specs, verify commit completeness
```

Change line 68 from:

```markdown
- **superpowers:using-git-worktrees** - Ensures isolated workspace (creates one or verifies existing)
```

to:

```markdown
- **superpowers:preparing-workspace** - Verifies workspace is clean and tests pass at baseline
```

Change line 70 from:

```markdown
- **superpowers:finishing-a-development-branch** - Complete development after all tasks
```

to:

```markdown
- **superpowers:finishing-work** - Run final checks, sync specs, verify commit completeness
```

- [ ] **Step 4: Update `skills/subagent-driven-development/SKILL.md`**

Change line 66 from:

```dot
    "Use superpowers:finishing-a-development-branch" [shape=box style=filled fillcolor=lightgreen];
```

to:

```dot
    "Use superpowers:finishing-work" [shape=box style=filled fillcolor=lightgreen];
```

Change line 81 from:

```dot
    "Dispatch final code reviewer subagent (../requesting-code-review/code-reviewer.md)" -> "Use superpowers:finishing-a-development-branch";
```

to:

```dot
    "Dispatch final code reviewer subagent (../requesting-code-review/code-reviewer.md)" -> "Use superpowers:finishing-work";
```

Change line 409 from:

```markdown
- **superpowers:using-git-worktrees** - Ensures isolated workspace (creates one or verifies existing)
```

to:

```markdown
- **superpowers:preparing-workspace** - Verifies workspace is clean and tests pass at baseline
```

Change line 412 from:

```markdown
- **superpowers:finishing-a-development-branch** - Complete development after all tasks
```

to:

```markdown
- **superpowers:finishing-work** - Run final checks, sync specs, verify commit completeness
```

- [ ] **Step 5: Update `skills/writing-plans/SKILL.md`**

Change line 16 from:

```markdown
**Context:** If working in an isolated worktree, it should have been created via the `superpowers:using-git-worktrees` skill at execution time.
```

to:

```markdown
**Context:** Before execution, the workspace should be prepared via the `superpowers:preparing-workspace` skill — clean tree and baseline tests verified.
```

- [ ] **Step 6: Delete the three old skill directories**

```bash
git rm -r skills/using-git-worktrees
git rm -r skills/finishing-a-development-branch
git rm -r skills/dispatching-parallel-agents
```

- [ ] **Step 7: Verify no stale references remain**

Run: `rg 'dispatching-parallel-agents|using-git-worktrees|finishing-a-development-branch' --type md -g '!docs/superpowers/**'`
Expected: no output (all live references updated; historical plan/spec docs under `docs/superpowers/` are archived and excluded).

- [ ] **Step 8: Verify new skill directories exist**

Run: `ls skills/preparing-workspace/SKILL.md skills/finishing-work/SKILL.md`
Expected: both files listed.

- [ ] **Step 9: Verify old skill directories are gone**

Run: `ls skills/using-git-worktrees skills/finishing-a-development-branch skills/dispatching-parallel-agents 2>&1`
Expected: "No such file or directory" for each.

- [ ] **Step 10: Commit**

```bash
git add README.md skills/executing-plans/SKILL.md skills/subagent-driven-development/SKILL.md skills/writing-plans/SKILL.md
git commit -m "refactor: replace worktree/branch skills with workspace-hygiene skills

Update all references from using-git-worktrees to preparing-workspace
and from finishing-a-development-branch to finishing-work. Remove
dispatching-parallel-agents. Delete the three old skill directories."
```
