# Simplify Workspace Skills Design

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove `dispatching-parallel-agents` and replace `using-git-worktrees` and `finishing-a-development-branch` with leaner skills that drop worktree/branch/PR machinery and keep only the workspace-hygiene and completion-gate value.

**Architecture:** Three existing skills are deleted. Two new skills (`preparing-workspace`, `finishing-work`) are created in new directories. Four files that reference the old skills are updated. No code changes outside the skills library.

**Tech Stack:** Markdown skill files, YAML frontmatter, shell commands for git/test detection.

## Global Constraints

- Skill names use letters, numbers, and hyphens only.
- YAML frontmatter `name` + `description` fields, max 1024 chars total.
- Descriptions start with "Use when..." and describe triggering conditions only, never workflow summary.
- No worktree creation, branch creation, merge, PR, or branch deletion logic in either new skill.
- No `npm install` / dependency install step (without worktrees, deps are already in-place).
- Spec sync is conditional on `docs/specs/changes/<feature>/` existing; no-op otherwise.
- Auto-detection of test/lint/typecheck commands must be conservative — only run commands the project actually defines.

## Motivation

The user does not need agents to work in separate worktrees or branches, and does not need agents to create PRs. The three skills targeted for removal/simplification carry substantial machinery for those workflows:

- `using-git-worktrees` (202 lines): ~90% is worktree creation, directory selection, gitignore verification, native-tool detection, submodule guards. The two transferable steps are baseline test verification and clean-tree checks.
- `finishing-a-development-branch` (251 lines): ~75% is merge/PR/discard options menus, worktree cleanup, branch deletion. The transferable steps are final test verification, spec-sync trigger, and commit-completeness verification.
- `dispatching-parallel-agents` (185 lines): Optional guidance for concurrent subagent dispatch. Not a dependency of any other skill. `subagent-driven-development` explicitly dispatches implementers sequentially.

## Design

### 1. Remove `dispatching-parallel-agents`

- Delete `skills/dispatching-parallel-agents/` directory.
- Remove its listing from `README.md` (line 79).
- No other skill depends on it. Historical references in `docs/superpowers/plans/` are left as-is (they are archived planning documents, not live configuration).

### 2. Replace `using-git-worktrees` with `preparing-workspace`

**Purpose:** Before starting new work, verify the workspace is clean (no uncommitted or untracked changes) and the test suite passes at baseline.

**Frontmatter:**
```yaml
name: preparing-workspace
description: Use when starting feature work or before executing an implementation plan - verifies the workspace is clean (no uncommitted or untracked changes) and the test suite passes at baseline
```

**Flow:**

1. **Clean check** — run `git status --porcelain`. If output is empty, skip to step 2. If any output, the workspace is dirty (uncommitted or untracked changes present).

2. **If dirty** — present exactly these 4 options:
   - **Commit** — stage and commit the pending changes. Ask the user for a commit message.
   - **Stash** — run `git stash push -u` (includes untracked files).
   - **Discard** — run `git checkout -- . && git clean -fd` (destructive; require typed confirmation).
   - **Abort** — stop. Do not start new work.

   Execute the chosen option, then re-run `git status --porcelain` to verify the workspace is now clean. If still dirty (e.g. commit failed), report and stop.

3. **Baseline tests** — auto-detect the test command:
   - `package.json` with `scripts.test` → `npm test`
   - `Cargo.toml` → `cargo test`
   - `pyproject.toml` or `requirements.txt` → `pytest`
   - `go.mod` → `go test ./...`
   - No recognized project file → skip silently, report "No test suite detected."

4. **If tests fail** — report the failures and ask whether to proceed or investigate. Do not assume baseline is green. Do not proceed without explicit consent.

5. **If tests pass** — report: "Workspace clean, <N> tests passing. Ready to implement <feature-name>."

**Does NOT do:** No worktree creation, no branch creation, no dependency installation, no native-tool detection.

**Common Mistakes section:**
- Proceeding with a dirty workspace (must resolve or abort first).
- Proceeding with failing baseline tests without explicit consent.
- Running `git clean -fd` without typed confirmation.
- Skipping the re-verify after commit/stash/discard.

**Red Flags section:**
- Never discard without typed confirmation.
- Never assume tests pass — run them and verify output.
- Never create a worktree or branch (this skill no longer does that).

### 3. Replace `finishing-a-development-branch` with `finishing-work`

**Purpose:** After implementation is complete and all tasks are done, run final checks, sync spec deltas, and verify all changes are committed.

**Frontmatter:**
```yaml
name: finishing-work
description: Use when implementation is complete and all tasks are done - runs final checks (tests, lint, typecheck), syncs spec deltas, and verifies all changes are committed
```

**Flow:**

1. **Final checks** — auto-detect from project:
   - **Tests:** `package.json` with `scripts.test` → `npm test`; `Cargo.toml` → `cargo test`; `pyproject.toml` or `requirements.txt` → `pytest`; `go.mod` → `go test ./...`. If no test runner detected, skip silently.
   - **Lint:** run if `package.json` has `scripts.lint` (→ `npm run lint`), or `.eslintrc*`/`eslint.config.*` exists (→ `npx eslint .`), or `ruff.toml`/`pyproject.toml` with ruff config exists (→ `ruff check`), or `.golangci.yml`/`.golangci.yaml` exists (→ `golangci-lint run`).
   - **Typecheck:** run if `package.json` has `scripts.typecheck` (→ `npm run typecheck`), or `tsconfig.json` exists (→ `npx tsc --noEmit`), or `mypy.ini`/`pyproject.toml` with mypy config exists (→ `mypy .`).
   - All detected checks must pass. If any fail: report failures, stop. Do not declare work complete.

2. **Spec sync** — check for `docs/specs/changes/<feature>/specs/*/spec.md`, where `<feature>` is the current branch name (`git rev-parse --abbrev-ref HEAD`). If deltas exist, invoke the `syncing-specs` skill. If `docs/specs/` does not exist or no deltas are found, skip silently. This is a no-op unless the project has opted into living specs.

3. **Commit completeness** — run `git status --porcelain`. If any output:
   - Report exactly what is uncommitted or untracked.
   - Ask the user to commit or stash before declaring work done.
   - Do not proceed to "work complete" with a dirty tree.

4. **If all clean** — report: "All checks pass, specs synced, all changes committed. Work complete."

**Does NOT do:** No merge, no PR, no branch deletion, no worktree cleanup, no options menu (merge/PR/keep/discard).

**Common Mistakes section:**
- Declaring work complete with failing checks.
- Declaring work complete with uncommitted changes.
- Skipping spec sync when deltas exist.
- Running spec sync when no deltas exist (wastes time).

**Red Flags section:**
- Never declare "work complete" with failing tests, lint, or typecheck.
- Never declare "work complete" with a dirty tree.
- Never merge, push, create PRs, delete branches, or clean up worktrees (this skill no longer does that).

### 4. Reference updates

| File | Changes |
|------|---------|
| `README.md` | Workflow step 2: `using-git-worktrees` → `preparing-workspace` with updated description (clean check + baseline tests). Workflow step 7: `finishing-a-development-branch` → `finishing-work` with updated description (final checks + spec sync + commit completeness). Remove `dispatching-parallel-agents` from skills listing (line 79). Update both skills' one-line descriptions in the skills listing (lines 82-83). |
| `skills/executing-plans/SKILL.md` | Step 3 (lines 35-37): `finishing-a-development-branch` → `finishing-work`. Integration section (lines 68, 70): update both skill names and descriptions. |
| `skills/subagent-driven-development/SKILL.md` | Process flowchart (lines 66, 81): `finishing-a-development-branch` → `finishing-work`. Integration section (lines 409, 412): update both skill names and descriptions. |
| `skills/writing-plans/SKILL.md` | Context line 16: replace worktree reference with `preparing-workspace` reference. |

### 5. Deletions

- `skills/using-git-worktrees/` — entire directory.
- `skills/finishing-a-development-branch/` — entire directory.
- `skills/dispatching-parallel-agents/` — entire directory.

## Files Touched

| File | Action |
|------|--------|
| `skills/preparing-workspace/SKILL.md` | Create |
| `skills/finishing-work/SKILL.md` | Create |
| `skills/using-git-worktrees/SKILL.md` | Delete |
| `skills/finishing-a-development-branch/SKILL.md` | Delete |
| `skills/dispatching-parallel-agents/SKILL.md` | Delete |
| `README.md` | Edit (workflow descriptions + skills listing) |
| `skills/executing-plans/SKILL.md` | Edit (Step 3 + Integration) |
| `skills/subagent-driven-development/SKILL.md` | Edit (flowchart + Integration) |
| `skills/writing-plans/SKILL.md` | Edit (Context line) |
