# OpenSpec-Style Spec Lifecycle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the OpenSpec-style delta/main spec lifecycle to the superpowers workflow — two new prose skills, three pointer blocks in existing skills, two README lines, one structural test — verified behaviorally in a throwaway scratch project.

**Architecture:** All new behavior lives in new files (`skills/writing-spec-deltas/`, `skills/syncing-specs/`, `tests/spec-lifecycle/`). The merge is agent-guided prose (no scripts, no dependencies). Existing files change only in additive pointer blocks. A structural bash test pins the integration anchors so an upstream merge that clobbers them fails loudly.

**Tech Stack:** Markdown skills (house prose style), bash structural tests (grep/awk), git.

**Spec:** `docs/superpowers/specs/2026-10-03-openspec-spec-lifecycle-design.md` — the plan argues from it; executors read both.

## Global Constraints

- The only existing files modified: `skills/brainstorming/SKILL.md` (one pointer block + the single gate-message line), `skills/subagent-driven-development/SKILL.md` (one pointer block), `skills/executing-plans/SKILL.md` (one pointer block), `README.md` (two list lines). No existing sentence except the gate-message line is reworded.
- No new scripts anywhere, no new runtime dependencies, no `openspec` CLI.
- Never create `docs/specs/` anywhere as a side effect — including this repo. `openspec-spec-lifecycle-report.md` stays untracked.
- Exact grammar strings: `### Requirement:`, `#### Scenario:` (exactly four hashtags), `## ADDED Requirements`, `## MODIFIED Requirements`, `## REMOVED Requirements`, `## RENAMED Requirements`, `**Reason**:`, `**Migration**:`, `FROM:`, `TO:`.
- Exact paths: `docs/specs/<capability-path>/spec.md`, `docs/specs/changes/<change-id>/specs/<capability-path>/spec.md`, `docs/specs/changes/archive/<change-id>/`; `changes` is a reserved capability name.
- Both new skills' frontmatter: `name` + `description` only (no `allowed-tools`); description starts `Use when`, names `docs/specs`, ≤1024 chars.
- Skill prose says "your human partner", never "the user"; no machine-specific paths or names in shipped files.
- Each new SKILL.md body ≤1500 words.
- Pointer anchors, exact: `superpowers:writing-spec-deltas` in brainstorming before the `**Spec Self-Review:**` label; `superpowers:syncing-specs` in both execution skills between `## Final Review` and `## Finish`.
- The merge-order string `RENAMED → REMOVED → MODIFIED → ADDED` appears in syncing-specs.
- Scratch exercise lives under `/tmp/opencode/`; nothing from it is committed.

## Review Focus

1. A pointer names a skill that doesn't exist or is typo'd — Task 3's exact-string anchor assertions plus Tasks 1–2's skill-existence assertions pin it.
2. A pointer sits in the wrong place (e.g., after Finish) — Task 3's placement assertions compare heading line numbers.
3. The new skills over-trigger in projects without `docs/specs/` — description gates (Tasks 1–2), the Never-create rule, and Task 4's bare-project skip check.
4. Grammar drift between writer and merger (an operation or marker taught by one, missing in the other) — Tasks 1–2's anchor loops assert all four operation sections and the scenario/requirement markers in both skills.
5. A merge that silently drops a scenario (the exact failure this design exists to prevent) — Task 4 stages a deliberately partial MODIFIED block and expects the guard to stop.

---

### Task 1: `writing-spec-deltas` skill + structural test (writer slice)

**Files:**
- Create: `tests/spec-lifecycle/test-skill-structure.sh`
- Create: `skills/writing-spec-deltas/SKILL.md`

**Interfaces:**
- Consumes: the spec's "Delta Grammar", "Artifact Model", and "Skill: `writing-spec-deltas`" sections.
- Produces: the test script's shared preamble and helpers (`check_skill`, `contains`, `frontmatter_name`, `frontmatter_description`, `body_words`), used by Tasks 2–3; the `skills/writing-spec-deltas/SKILL.md` whose exact anchor strings the test asserts.

- [ ] **Step 1: Write the failing test — create `tests/spec-lifecycle/test-skill-structure.sh`**

```bash
#!/usr/bin/env bash
# Structural checks for the spec-lifecycle skills (writing-spec-deltas,
# syncing-specs) and their integration points. Merge behavior is prose and
# is exercised in a throwaway scratch project at implementation time; this
# script checks what a shell can check: frontmatter, word budget, grammar
# anchors, and — the fork's real guard — that the pointer blocks sit in the
# three edited skills and README exactly where the design spec puts them,
# so an upstream merge that clobbers or moves one fails loudly.
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORD_BUDGET=1500

PASSES=0
FAILURES=0

pass() { echo "  [PASS] $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  [FAIL] $1"; FAILURES=$((FAILURES + 1)); }

frontmatter_name() {
  awk 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} NR>1{print}' "$1" \
    | grep -q "^name: $2$"
}

frontmatter_description() {
  awk 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} NR>1{print}' "$1" \
    | awk '/^description:/{sub(/^description:[ ]*/,""); print; found=1; next} found && /^[ ]/{print} found && !/^[ ]/{exit}' \
    | tr '\n' ' '
}

body_words() {
  awk 'BEGIN{fm=0} NR==1 && $0=="---"{fm=1; next} fm==1 && $0=="---"{fm=2; next} fm==2{print}' "$1" | wc -w | tr -d ' '
}

# check_skill SKILL_NAME — pass/fail the house frontmatter + budget checks.
check_skill() {
  skill="$1"
  md="$REPO_ROOT/skills/$skill/SKILL.md"
  if [ -f "$md" ]; then
    pass "skills/$skill/SKILL.md exists"
  else
    fail "skills/$skill/SKILL.md exists"
    return 1
  fi
  if frontmatter_name "$md" "$skill"; then
    pass "$skill: frontmatter name is $skill"
  else
    fail "$skill: frontmatter name is $skill"
  fi
  desc="$(frontmatter_description "$md")"
  if printf '%s' "$desc" | grep -q '^Use when'; then
    pass "$skill: description starts with 'Use when'"
  else
    fail "$skill: description starts with 'Use when' (got: ${desc:0:60})"
  fi
  if printf '%s' "$desc" | grep -q 'docs/specs'; then
    pass "$skill: description names docs/specs (trigger gate)"
  else
    fail "$skill: description names docs/specs (trigger gate)"
  fi
  if [ "${#desc}" -le 1024 ]; then
    pass "$skill: description under 1024 characters"
  else
    fail "$skill: description under 1024 characters (${#desc})"
  fi
  if grep -q '^allowed-tools:' "$md"; then
    fail "$skill: no allowed-tools frontmatter (house style)"
  else
    pass "$skill: no allowed-tools frontmatter (house style)"
  fi
  words="$(body_words "$md")"
  if [ "$words" -le "$WORD_BUDGET" ]; then
    pass "$skill: SKILL.md body within $WORD_BUDGET words ($words)"
  else
    fail "$skill: SKILL.md body within $WORD_BUDGET words ($words)"
  fi
  return 0
}

# contains FILE NEEDLE LABEL
contains() {
  if grep -q -- "$2" "$1"; then
    pass "$3"
  else
    fail "$3"
  fi
}

echo "spec-lifecycle structure"

# --- writing-spec-deltas ---------------------------------------------------
if check_skill writing-spec-deltas; then
  WSD="$REPO_ROOT/skills/writing-spec-deltas/SKILL.md"
  for anchor in "## Project Check" "## When a Delta Is Appropriate" "## Inventory" "## Author the Deltas" "## Delta Grammar" "## Self-Validate" "## Hand Off" \
    "## ADDED Requirements" "## MODIFIED Requirements" "## REMOVED Requirements" "## RENAMED Requirements" \
    "#### Scenario:" "### Requirement:" "docs/specs/changes/" "Never create" "reserved" "## Purpose"; do
    contains "$WSD" "$anchor" "writing-spec-deltas carries anchor: $anchor"
  done
fi

# --- house voice + leak checks ---------------------------------------------
for skill in writing-spec-deltas syncing-specs; do
  md="$REPO_ROOT/skills/$skill/SKILL.md"
  if [ -f "$md" ]; then
    if grep -qi 'the user' "$md"; then
      fail "$skill: says 'the user' instead of 'your human partner'"
    else
      pass "$skill: says 'your human partner', not 'the user'"
    fi
    if grep -rn -E '/Users/|/home/' "$REPO_ROOT/skills/$skill" --include='*.md' 2>/dev/null; then
      fail "$skill: machine-specific paths in shipped files"
    else
      pass "$skill: no machine-specific paths in shipped files"
    fi
  fi
done

echo
echo "Passed: $PASSES  Failed: $FAILURES"
[ "$FAILURES" -eq 0 ]
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/spec-lifecycle/test-skill-structure.sh`
Expected: FAIL — one line `  [FAIL] skills/writing-spec-deltas/SKILL.md exists`, then `Passed: 0  Failed: 1`, exit code 1. The voice/leak loop stays silent (file missing).

- [ ] **Step 3: Implement `skills/writing-spec-deltas/SKILL.md`**

Frontmatter exactly:

```yaml
---
name: writing-spec-deltas
description: Use when a design spec has been written during brainstorming and the project maintains canonical capability specs in `docs/specs/` — writes this change's OpenSpec-style delta specs under `docs/specs/changes/`. Also use when your human partner explicitly asks for a delta spec on a bounded change.
---
```

Body: the seven sections named in the test's anchor loop, prose written from the spec's "Skill: `writing-spec-deltas`" section (its bullets: Project check / Appropriateness / Inventory / Author / Self-validate / Hand off) and the spec's normative "Delta Grammar" and "Artifact Model" sections — those are the content authority; do not restate them here. Constraints the body must honor (the test asserts the exact strings): the literal phrases `Never create`, `reserved` (for the `changes` name), and `docs/specs/changes/`; the four operation-section names and `### Requirement:` / `#### Scenario:` markers appear in the grammar; `## Purpose` appears in the new-capability rule; `change-id` is defined as the design doc filename minus its `-design` suffix. The body stays ≤1500 words and says "your human partner", never "the user".

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/spec-lifecycle/test-skill-structure.sh`
Expected: PASS — `Passed: 26  Failed: 0` (7 check_skill + 17 anchors + 2 voice/leak), exit code 0.

- [ ] **Step 5: Lint the test script**

Run: `scripts/lint-shell.sh tests/spec-lifecycle/test-skill-structure.sh`
Expected: PASS (no shellcheck or syntax findings).

- [ ] **Step 6: Commit**

```bash
git add skills/writing-spec-deltas/SKILL.md tests/spec-lifecycle/test-skill-structure.sh
git commit -m "feat(spec-lifecycle): writing-spec-deltas skill and structural test"
```

### Task 2: `syncing-specs` skill (merger slice)

**Files:**
- Modify: `tests/spec-lifecycle/test-skill-structure.sh` (append a syncing-specs section)
- Create: `skills/syncing-specs/SKILL.md`

**Interfaces:**
- Consumes: the test helpers produced by Task 1; the spec's "Skill: `syncing-specs`", "Main Spec Shape", and "Delta Grammar" sections.
- Produces: `skills/syncing-specs/SKILL.md` whose exact anchor strings the test asserts; the skill Task 4 exercises and Task 3's pointers reference.

- [ ] **Step 1: Write the failing test — insert this section after the writing-spec-deltas section**

```bash
# --- syncing-specs -----------------------------------------------------------
if check_skill syncing-specs; then
  SS="$REPO_ROOT/skills/syncing-specs/SKILL.md"
  for anchor in "## Project Check" "## Resolve the Change" "## Reconcile" "## Validate" \
    "## Merge (RENAMED → REMOVED → MODIFIED → ADDED)" "## New Capability" "## Retirement" \
    "## Verify" "## Archive" "## Report and Commit" \
    "## ADDED Requirements" "## MODIFIED Requirements" "## REMOVED Requirements" "## RENAMED Requirements" \
    "#### Scenario:" "### Requirement:" "docs/specs/changes/archive/" \
    "Reason" "Migration" "FROM:" "TO:" "scenario-loss" "Never create" "reserved"; do
    contains "$SS" "$anchor" "syncing-specs carries anchor: $anchor"
  done
fi
```

- [ ] **Step 2: Run test to verify the new slice fails**

Run: `bash tests/spec-lifecycle/test-skill-structure.sh`
Expected: FAIL — `  [FAIL] skills/syncing-specs/SKILL.md exists`, `Passed: 26  Failed: 1`, exit code 1 (writing-spec-deltas section still green; its voice/leak loop now passes too, hence 26).

- [ ] **Step 3: Implement `skills/syncing-specs/SKILL.md`**

Frontmatter exactly:

```yaml
---
name: syncing-specs
description: Use when a plan's implementation is complete, before Finish, and the project maintains canonical capability specs in `docs/specs/` — validates the change's delta specs, merges them into the canonical specs in `docs/specs/`, and archives the change under `docs/specs/changes/archive/`.
---
```

Body: the ten sections named in the test's anchor loop, prose written from the spec's "Skill: `syncing-specs`" section — its bullets are the content authority (Project check + resolve / Reconcile / Validate / Merge with the four per-operation semantics and the scenario-loss guard / New capability / Retirement / Verify / Archive / Report and commit). The body must contain the exact strings the test asserts, notably the heading `## Merge (RENAMED → REMOVED → MODIFIED → ADDED)`, `docs/specs/changes/archive/`, the words `scenario-loss`, `Reason`, `Migration`, `FROM:`, `TO:`, `Never create`, and `reserved`. ≤1500 words; "your human partner", never "the user".

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/spec-lifecycle/test-skill-structure.sh`
Expected: PASS — `Passed: 59  Failed: 0` (26 prior + 7 check_skill + 24 anchors + 2 voice/leak), exit code 0.

- [ ] **Step 5: Commit**

```bash
git add skills/syncing-specs/SKILL.md tests/spec-lifecycle/test-skill-structure.sh
git commit -m "feat(spec-lifecycle): syncing-specs skill"
```

### Task 3: Integration surfaces — pointer blocks + README + anchor tests

**Files:**
- Modify: `tests/spec-lifecycle/test-skill-structure.sh` (append integration section)
- Modify: `skills/brainstorming/SKILL.md:245-246` (insert block before the `**Spec Self-Review:**` label) and `:259` (the one sanctioned line edit)
- Modify: `skills/subagent-driven-development/SKILL.md:469-471` (insert block between the Final Review last paragraph and `## Finish`)
- Modify: `skills/executing-plans/SKILL.md:289-291` (same placement)
- Modify: `README.md:353-354` (insert two list lines in the Collaboration list)

**Interfaces:**
- Consumes: both skills from Tasks 1–2 (the pointers reference them by exact name).
- Produces: the wired-in workflow hooks — brainstorming invokes `superpowers:writing-spec-deltas`; both execution skills invoke `superpowers:syncing-specs` before `## Finish`.

- [ ] **Step 1: Write the failing test — insert this section after the syncing-specs section, before the voice/leak loop**

```bash
# --- pointer blocks in the three edited skills + README ----------------------
BS="$REPO_ROOT/skills/brainstorming/SKILL.md"
SDD="$REPO_ROOT/skills/subagent-driven-development/SKILL.md"
EP="$REPO_ROOT/skills/executing-plans/SKILL.md"

contains "$BS" "superpowers:writing-spec-deltas" "brainstorming points at superpowers:writing-spec-deltas"
contains "$SDD" "superpowers:syncing-specs" "subagent-driven-development points at superpowers:syncing-specs"
contains "$EP" "superpowers:syncing-specs" "executing-plans points at superpowers:syncing-specs"
contains "$BS" "and its spec delta, if the project maintains one" "brainstorming user review gate names the delta"

bs_anchor="$(grep -n 'superpowers:writing-spec-deltas' "$BS" | head -1 | cut -d: -f1)"
bs_selfreview="$(grep -n '\*\*Spec Self-Review:\*\*' "$BS" | head -1 | cut -d: -f1)"
if [ -n "$bs_anchor" ] && [ -n "$bs_selfreview" ] && [ "$bs_anchor" -lt "$bs_selfreview" ]; then
  pass "brainstorming pointer sits before the spec self-review"
else
  fail "brainstorming pointer sits before the spec self-review (anchor=$bs_anchor selfreview=$bs_selfreview)"
fi

pointer_between() {
  md="$1"
  skill="$2"
  a="$(grep -n 'superpowers:syncing-specs' "$md" | head -1 | cut -d: -f1)"
  f="$(grep -n '^## Final Review$' "$md" | head -1 | cut -d: -f1)"
  n="$(grep -n '^## Finish$' "$md" | head -1 | cut -d: -f1)"
  if [ -n "$a" ] && [ -n "$f" ] && [ -n "$n" ] && [ "$a" -gt "$f" ] && [ "$a" -lt "$n" ]; then
    pass "$skill pointer sits between Final Review and Finish"
  else
    fail "$skill pointer sits between Final Review and Finish (anchor=$a final=$f finish=$n)"
  fi
}
pointer_between "$SDD" "subagent-driven-development"
pointer_between "$EP" "executing-plans"

README="$REPO_ROOT/README.md"
contains "$README" '**writing-spec-deltas** - OpenSpec-style delta specs at design time' "README lists writing-spec-deltas"
contains "$README" '**syncing-specs** - Merge delta specs into canonical specs' "README lists syncing-specs"
```

- [ ] **Step 2: Run test to verify the new slice fails**

Run: `bash tests/spec-lifecycle/test-skill-structure.sh`
Expected: FAIL — 9 new failures (three pointers, gate clause, brainstorming placement, two `pointer_between`, two README lines), `Passed: 59  Failed: 9`, exit code 1.

- [ ] **Step 3: Apply the brainstorming edit**

Insert this block between the Documentation subsection's last line (`- Commit the design document to git`) and the `**Spec Self-Review:**` label, as its own paragraph:

```markdown
**Spec delta (projects that maintain canonical specs):** If the project has a
`docs/specs/` directory, invoke superpowers:writing-spec-deltas now — after
the design doc is written, before the self-review — to write this change's
spec delta. The delta file(s) join the design doc in the spec self-review and
the user review gate below, and are committed with it. If `docs/specs/` does
not exist, skip: never create it as a side effect.
```

Then edit the User Review Gate message line (the single sanctioned line modification), from:

> "Spec written and committed to `<path>`. Please review it and let me know if you want to make any changes before we start writing out the implementation plan."

to:

> "Spec written and committed to `<path>` — and its spec delta, if the project maintains one. Please review both and let me know if you want to make any changes before we start writing out the implementation plan."

- [ ] **Step 4: Apply the two execution-skill edits**

Insert this block between the Final Review section's last paragraph and the `## Finish` heading in BOTH `skills/subagent-driven-development/SKILL.md` and `skills/executing-plans/SKILL.md`:

```markdown
**Spec sync (projects that maintain canonical specs):** After the final
review is clean and its fixes are committed, and before Finish: if the
project has a `docs/specs/` directory, resolve this plan's change (its
`**Spec:**` design doc → `docs/specs/changes/<stem>/`) and, if it has delta
specs, invoke superpowers:syncing-specs to validate and merge them into the
canonical specs and archive the change — before this plan's workspace is
deleted (the sync reads the ledger's rulings). No `docs/specs/`, or no
deltas for this change → skip.
```

- [ ] **Step 5: Apply the README edit**

In the Collaboration list under "What's Inside": insert directly after the `- **writing-plans** - Detailed implementation plans` line:

```markdown
- **writing-spec-deltas** - OpenSpec-style delta specs at design time (opt-in per project via `docs/specs/`)
```

and directly after the `- **executing-plans** - Inline plan execution: one context, one final review` line:

```markdown
- **syncing-specs** - Merge delta specs into canonical specs when implementation ends (opt-in per project via `docs/specs/`)
```

- [ ] **Step 6: Verify the diff shape is additive-only**

Run: `git diff --numstat -- skills/brainstorming/SKILL.md skills/subagent-driven-development/SKILL.md skills/executing-plans/SKILL.md README.md`
Expected: deletions column `0` for `README.md`, `subagent-driven-development/SKILL.md`, `executing-plans/SKILL.md`; for `brainstorming/SKILL.md` exactly `1` deletion (the original gate-message line). No other lines touched.

- [ ] **Step 7: Run test to verify it passes**

Run: `bash tests/spec-lifecycle/test-skill-structure.sh`
Expected: PASS — `Passed: 68  Failed: 0`, exit code 0.

- [ ] **Step 8: Lint and commit**

Run: `scripts/lint-shell.sh tests/spec-lifecycle/test-skill-structure.sh`
Expected: PASS.

```bash
git add tests/spec-lifecycle/test-skill-structure.sh skills/brainstorming/SKILL.md skills/subagent-driven-development/SKILL.md skills/executing-plans/SKILL.md README.md
git commit -m "feat(spec-lifecycle): wire spec-lifecycle hooks into brainstorming, execution skills, README"
```

### Task 4: Scratch-project behavioral exercise

**Files:**
- None in the repo. Scratch trees live under `/tmp/opencode/` and are removed at the end. Nothing from this task is committed.

**Interfaces:**
- Consumes: `skills/writing-spec-deltas/SKILL.md` and `skills/syncing-specs/SKILL.md` prose (Tasks 1–2).
- Produces: the exercise report (findings feed the final whole-branch review); confirmation that the repo is untouched.

- [ ] **Step 1: Seed the scratch project**

Create `/tmp/opencode/spec-lifecycle-exercise/` with:

`docs/superpowers/specs/2026-10-03-demo-feature-design.md` — a minimal design doc whose sections state: add a `session-management` capability (sign-in audit trail); add lockout after 5 failed password attempts to `user-auth`; rename "Session timeout" to "Idle timeout"; retire `legacy-login`.

`docs/superpowers/plans/2026-10-03-demo-feature.md` — a minimal plan header whose `**Spec:**` field names `docs/superpowers/specs/2026-10-03-demo-feature-design.md`.

`docs/specs/user-auth/spec.md`:

```markdown
# user-auth Specification

## Purpose
Lets signed-in users access their account with a username and password, with sessions that expire after inactivity.

## Requirements

### Requirement: Password login
The system SHALL authenticate a user with a valid username and password.

#### Scenario: Valid credentials
- **WHEN** a user submits a registered username and correct password
- **THEN** the system creates an authenticated session

#### Scenario: Wrong password
- **WHEN** a user submits a registered username and an incorrect password
- **THEN** the system rejects the attempt with an error

### Requirement: Session timeout
The system SHALL end sessions after 30 minutes of inactivity.

#### Scenario: Idle session
- **WHEN** a session is idle for 30 minutes
- **THEN** the system ends the session
```

`docs/specs/legacy-login/spec.md` — one requirement, `### Requirement: Legacy token login`, with one scenario.

- [ ] **Step 2: Exercise `writing-spec-deltas` by following its prose**

Act as the skill instructs: project check → appropriateness → inventory → author → self-validate.
Expected: three delta files at exactly `docs/specs/changes/2026-10-03-demo-feature/specs/session-management/spec.md` (with `## Purpose` + `## ADDED Requirements`), `.../specs/user-auth/spec.md` (with `## RENAMED Requirements` FROM "Session timeout" TO "Idle timeout", `## MODIFIED Requirements` for "Password login" carrying BOTH original scenarios plus the new lockout scenario), and `.../specs/legacy-login/spec.md` (`## REMOVED Requirements` for "Legacy token login" with `**Reason**` and `**Migration**`). Any place the prose left you choosing between two reasonable readings is a finding — record it.

- [ ] **Step 3: Stage the scenario-loss trap**

Edit the delta's MODIFIED "Password login" block to drop the "Wrong password" scenario, then follow `syncing-specs`' merge prose on `user-auth` only.
Expected: the scenario-loss guard's stop condition is reached — the prose instructs you to stop and restore the omitted scenario, not to merge. Restore the scenario. Record whether the instruction was unambiguous.

- [ ] **Step 4: Exercise `syncing-specs` fully — resolve, validate, merge, archive**

Follow the prose end to end.
Expected: `docs/specs/session-management/spec.md` created with the skeleton and the delta's Purpose verbatim; `user-auth` merged in order — RENAMED rewritten in place (position preserved, "Idle timeout" still second), MODIFIED whole-block with three scenarios; the `legacy-login` retirement stop reached — the prose instructs stopping and asking your human partner; acting as the partner, approve → the main spec file is deleted and the empty directory pruned, the report names it; the change dir moved whole to `docs/specs/changes/archive/2026-10-03-demo-feature/`; per-capability totals reported. Record every ambiguity as a finding.

- [ ] **Step 5: Exercise the no-`docs/specs` skip**

Create `/tmp/opencode/spec-lifecycle-bare/` (a git repo with a trivial plan and design doc, no `docs/specs/`), and re-read both skills' Project-check prose against it.
Expected: both skills' prose says skip — and no `docs/specs/` was created.

- [ ] **Step 6: Clean up and verify the repo is untouched**

Run: `rm -rf /tmp/opencode/spec-lifecycle-exercise /tmp/opencode/spec-lifecycle-bare && git status --porcelain && bash tests/spec-lifecycle/test-skill-structure.sh`
Expected: `git status --porcelain` prints nothing (scratch content never entered the repo); the structural test passes with `Passed: 68  Failed: 0`.

- [ ] **Step 7: Report**

The implementer's report lists: each expected outcome above and whether it held, and every prose ambiguity found (each is a finding for the final whole-branch review; fix none silently).
