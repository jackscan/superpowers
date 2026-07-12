# Temporary, Unambiguous Execution Handoff Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the planning-to-execution handoff document temporary (gitignored scratch, deleted at completion) and unambiguous to find (one fixed path, no scanning, no name needed to start execution).

**Architecture:** The handoff doc moves from a permanent per-plan file (`docs/superpowers/plans/YYYY-MM-DD-<feature>-handoff.md`) to a single fixed gitignored scratch path (`.superpowers/execution-handoff.md`), overwritten on each new plan and deleted by `finishing-work` at completion. `plan-execution-entry` reads exactly that one path with a clean ask-for-plan-path fallback. The start prompt collapses to "Load the plan-execution-entry skill." The handoff template content is unchanged. Three skill markdown files are edited; `README.md` needs no change.

**Tech Stack:** Markdown skill files, YAML frontmatter.

## Global Constraints

- Skill names use letters, numbers, and hyphens only.
- YAML frontmatter `name` + `description` fields, max 1024 chars total.
- Descriptions start with "Use when..." and describe triggering conditions only, never workflow summary.
- The handoff doc is a Markdown scratch file. No new scripts or plugin tooling.
- `.superpowers/` is already listed in `.gitignore`; no gitignore changes are required.
- Exactly one handoff exists at any time. A new plan overwrites the previous handoff.
- The execution skill decision (subagent-driven vs executing-plans) is still made by the human user in the execution session.
- Starting a new session is still recommended but not enforced.
- Backward compatibility: repos that never generated a handoff (or where `finishing-work` already deleted it) fall back to the user supplying a plan path manually.
- No plugin code, no tests under `tests/`. Verification is reading the edited files and running `grep` checks on the exact strings.

---

### Task 1: Update `writing-plans` skill — handoff save path + start prompt

**Files:**
- Modify: `skills/writing-plans/SKILL.md` (the "Handoff Document" section and the "Execution Handoff" section)

**Interfaces:**
- Produces: handoff docs written to `.superpowers/execution-handoff.md` (overwrite semantics); a simplified start prompt that references `plan-execution-entry` without a plan path.
- Consumes: the `plan-execution-entry` skill (referenced by name in the Execution Handoff message).

- [ ] **Step 1: Edit the "Handoff Document" section — save path and storage note**

In `skills/writing-plans/SKILL.md`, find this exact text inside the "Handoff Document" section:

```markdown
After the plan and self-review are complete, generate a handoff document alongside the plan. This carries the "why" and "watch out for" context that the spec and plan don't capture — the planning orchestrator's distilled summary of what it learned, not a transcript.

**Save to:** `docs/superpowers/plans/YYYY-MM-DD-<feature>-handoff.md` (same naming convention as the plan, with `-handoff` suffix).
```

Replace it with:

```markdown
After the plan and self-review are complete, generate a handoff document as a temporary scratch file. This carries the "why" and "watch out for" context that the spec and plan don't capture — the planning orchestrator's distilled summary of what it learned, not a transcript.

**Save to:** `.superpowers/execution-handoff.md` — a single, fixed, gitignored scratch path. This overwrites any previous handoff; exactly one handoff exists at a time. `finishing-work` deletes it when execution completes. It never enters git (`.superpowers/` is already in `.gitignore`).
```

- [ ] **Step 2: Edit the handoff template's blockquote line**

In the same section, inside the template code block, find:

```markdown
> This document bridges planning and execution. Read this first, then the plan.
```

Replace it with:

```markdown
> This document bridges planning and execution. Read this first, then the plan. It is a temporary scratch file, deleted when execution completes.
```

- [ ] **Step 3: Edit the handoff template's start-prompt line**

Still inside the template code block, find:

```markdown
Start a new session and give it a prompt like:
"Read the handoff at [path]. I want to use [chosen skill] to execute
the plan at [plan path]."
```

Replace it with:

```markdown
Start a new session and give it this prompt:
"Load the plan-execution-entry skill."
```

- [ ] **Step 4: Edit the "Generation" note**

Find:

```markdown
**Generation:** Distill this from the planning conversation. The handoff doc is always written after the plan is finalized. If the plan is revised, regenerate the handoff doc.
```

Replace it with:

```markdown
**Generation:** Distill this from the planning conversation. The handoff doc is always written after the plan is finalized. If the plan is revised, regenerate the handoff doc — writing to the fixed scratch path always overwrites the previous handoff.
```

- [ ] **Step 5: Replace the entire "Execution Handoff" section**

Find the entire current "Execution Handoff" section (from the heading `## Execution Handoff` through the final line `conversation, which costs tokens without benefiting execution."`):

```markdown
## Execution Handoff

After saving the plan and handoff document, present the handoff message:

**"Plan and handoff document saved:**
- Plan: `docs/superpowers/plans/<filename>.md`
- Handoff: `docs/superpowers/plans/<filename>-handoff.md`

**Recommended: Start a new session for execution.** The planning phase
accumulated context that the execution orchestrator doesn't need. A
fresh session starts with just the plan, spec, and handoff context.

Start a new session and give it this prompt:
`Load the plan-execution-entry skill and execute the plan at
docs/superpowers/plans/<filename>.md`

The entry skill will read the handoff, ask you which execution
approach to use, and load the chosen skill.

**Alternatively**, you can stay in this session and load an execution
skill directly — but your context will carry the planning
conversation, which costs tokens without benefiting execution."
```

Replace it with:

```markdown
## Execution Handoff

After saving the plan and handoff document, present the handoff message:

**"Plan and handoff document saved:**
- Plan: `docs/superpowers/plans/<filename>.md`
- Handoff (scratch): `.superpowers/execution-handoff.md`

**Recommended: Start a new session for execution.** The planning phase
accumulated context that the execution orchestrator doesn't need. A
fresh session starts with just the plan, spec, and handoff context.

Start a new session and give it this prompt:
`Load the plan-execution-entry skill.`

The entry skill reads `.superpowers/execution-handoff.md`, which
points at the plan and spec, asks you which execution approach to use,
and loads the chosen skill. The execution skill, via `finishing-work`,
deletes the scratch handoff when work completes — the handoff never
persists in the repo.

**Alternatively**, you can stay in this session and load an execution
skill directly — but your context will carry the planning
conversation, which costs tokens without benefiting execution."
```

- [ ] **Step 6: Verify the changes**

Run: `grep -n "Save to:" skills/writing-plans/SKILL.md`
Expected: one match, the `.superpowers/execution-handoff.md` line.

Run: `grep -n "docs/superpowers/plans/YYYY-MM-DD-<feature>-handoff" skills/writing-plans/SKILL.md`
Expected: no output (old permanent handoff path removed everywhere it appeared as a save target).

Run: `grep -n "Load the plan-execution-entry skill\." skills/writing-plans/SKILL.md`
Expected: exactly two matches — one inside the template code block, one in the Execution Handoff section.

Run: `grep -n "execute the plan at" skills/writing-plans/SKILL.md`
Expected: no output (old prompt that embedded a plan path is gone).

- [ ] **Step 7: Commit**

```bash
git add skills/writing-plans/SKILL.md
git commit -m "refactor: move handoff doc to fixed scratch path, simplify start prompt

writing-plans now saves the handoff to .superpowers/execution-handoff.md
(gitignored scratch, overwrite-on-new-plan, deleted by finishing-work)
instead of a permanent per-plan file. The execution start prompt
collapses to 'Load the plan-execution-entry skill.' since the handoff
itself carries the plan path."
```

---

### Task 2: Simplify `plan-execution-entry` — read one fixed path or fall back

**Files:**
- Modify: `skills/plan-execution-entry/SKILL.md` (Step 1 and Step 4)

**Interfaces:**
- Consumes: `.superpowers/execution-handoff.md` written by `writing-plans` (Task 1's new behavior).
- Produces: a single unambiguous entry point that needs no plan name from the user.

- [ ] **Step 1: Replace Step 1 (Find the Handoff Doc)**

In `skills/plan-execution-entry/SKILL.md`, find the entire current Step 1 block:

```markdown
### Step 1: Find the Handoff Doc

If the user's prompt includes a plan path (e.g., `docs/superpowers/plans/YYYY-MM-DD-feature.md`), look for the handoff doc at the same path with `-handoff` suffix (e.g., `docs/superpowers/plans/YYYY-MM-DD-feature-handoff.md`).

- **Handoff doc found:** Use it. Continue to Step 2.
- **Handoff doc not found at that path:** Proceed to Step 3 using the plan path the user provided (legacy flow — no handoff doc).
- **No plan path in the prompt:** Scan `docs/superpowers/plans/` for `*-handoff.md` files.
  - Exactly one found: use it.
  - Multiple found: list them with timestamps and ask the user which one to use.
  - None found: ask the user for the plan path. Continue to Step 3 (legacy flow — no handoff doc).
```

Replace it with:

```markdown
### Step 1: Find the Handoff Doc

Read `.superpowers/execution-handoff.md` — the single, fixed, gitignored scratch path where `writing-plans` always writes the most recent handoff.

- **Handoff doc found:** Extract the `**Plan:**` and `**Spec:**` paths from its header. Continue to Step 2.
- **Handoff doc not found:** Ask the user for the plan path. Continue to Step 3 (legacy fallback — no handoff context).

There is exactly one handoff at any time (a new plan overwrites the previous one), so there is never a list to choose from and no name for the user to remember.
```

- [ ] **Step 2: Tweak Step 4 wording — note the handoff persists through execution**

Find the current Step 4:

```markdown
### Step 4: Load the Chosen Skill

Invoke the chosen skill via the `skill` tool. The chosen skill takes over from here — it reads the plan as part of its normal step 1.
```

Replace it with:

```markdown
### Step 4: Load the Chosen Skill

Invoke the chosen skill via the `skill` tool. The chosen skill takes over from here — it reads the plan as part of its normal step 1. The handoff doc persists at `.superpowers/execution-handoff.md` through execution and is deleted by `finishing-work` when work completes; this skill does not delete it.
```

- [ ] **Step 3: Verify the changes**

Run: `grep -n "Scan \`docs/superpowers/plans/\`" skills/plan-execution-entry/SKILL.md`
Expected: no output (the scanning branch is gone).

Run: `grep -n "Multiple found" skills/plan-execution-entry/SKILL.md`
Expected: no output (the multi-handoff branch is gone).

Run: `grep -n "\.superpowers/execution-handoff\.md" skills/plan-execution-entry/SKILL.md`
Expected: at least two matches — one in Step 1, one in Step 4.

Run: `grep -n "Ask the user for the plan path" skills/plan-execution-entry/SKILL.md`
Expected: one match, the legacy fallback line in Step 1.

- [ ] **Step 4: Verify frontmatter constraints are unchanged**

Run: `node -e "const fs=require('fs');const c=fs.readFileSync('skills/plan-execution-entry/SKILL.md','utf8');const m=c.match(/---\n([\s\S]*?)\n---/);const fm=m[1];const lines=fm.split('\n');let len=0;for(const l of lines){len+=l.length+1}console.log('frontmatter chars:',len);const name=fm.match(/name:\s*(.+)/);const desc=fm.match(/description:\s*(.+)/);console.log('name:',name[1]);console.log('desc starts with Use:',desc[1].startsWith('Use'));"`
Expected: frontmatter chars under 1024, name is `plan-execution-entry`, desc starts with `Use`. (No frontmatter changes were made in this task.)

- [ ] **Step 5: Commit**

```bash
git add skills/plan-execution-entry/SKILL.md
git commit -m "refactor: plan-execution-entry reads one fixed handoff path

Replace the three-branch discovery (prompt plan path → suffix lookup;
scan docs/superpowers/plans/ for *-handoff.md; list and choose) with a
single read of .superpowers/execution-handoff.md, falling back to
asking the user for a plan path when absent. Note in Step 4 that the
handoff persists through execution and is cleaned up by finishing-work."
```

---

### Task 3: Add scratch-handoff cleanup to `finishing-work`

**Files:**
- Modify: `skills/finishing-work/SKILL.md` (insert a new Step between Step 3 and Step 4; update the Quick Reference table; update the Red Flags **Always** list)

**Interfaces:**
- Consumes: `.superpowers/execution-handoff.md` produced by `writing-plans` (Task 1).
- Produces: a final cleanup action that deletes the scratch handoff once all checks pass and the tree is clean.

- [ ] **Step 1: Insert a new cleanup step between Step 3 and Step 4**

In `skills/finishing-work/SKILL.md`, find:

```markdown
## Step 4: Report Complete

```
All checks pass, specs synced, all changes committed.
Work complete.
```
```

Insert a new step *before* it, so the sequence becomes:

```markdown
## Step 4: Delete Scratch Handoff

Once all checks pass and the tree is clean, delete the scratch handoff left by the planning phase:

```bash
rm -f .superpowers/execution-handoff.md
```

`rm -f` makes this idempotent: a no-op if no handoff exists (e.g. a project that never generated one, or executing a legacy plan without a handoff).

## Step 5: Report Complete

```
All checks pass, specs synced, all changes committed.
Work complete.
```
```

(Renumber the old "Step 4: Report Complete" to "Step 5: Report Complete".)

- [ ] **Step 2: Update the Quick Reference table**

Find:

```markdown
| Clean tree, all checks pass | Declare work complete |
```

Replace it with:

```markdown
| Clean tree, all checks pass | Declare work complete, delete scratch handoff |
```

- [ ] **Step 3: Update the Red Flags **Always** list**

Find:

```markdown
**Always:**
- Run all project checks and verify output
- Check for spec deltas before declaring done
- Verify `git status --porcelain` is empty
```

Replace it with:

```markdown
**Always:**
- Run all project checks and verify output
- Check for spec deltas before declaring done
- Verify `git status --porcelain` is empty
- Delete `.superpowers/execution-handoff.md` as the final action once all checks pass and the tree is clean
```

- [ ] **Step 4: Verify the changes**

Run: `grep -n "Delete Scratch Handoff\|Step 4: Delete Scratch" skills/finishing-work/SKILL.md`
Expected: one match, the new step heading.

Run: `grep -n "rm -f .superpowers/execution-handoff.md" skills/finishing-work/SKILL.md`
Expected: one match, inside the new step.

Run: `grep -n "Step 5: Report Complete" skills/finishing-work/SKILL.md`
Expected: one match (renumbered from Step 4).

Run: `grep -c "Step 4: Report Complete" skills/finishing-work/SKILL.md`
Expected: `0` (the old unnumbered-as-Step-5 heading is gone — it's now Step 5).

Run: `grep -n "Delete .superpowers/execution-handoff.md as the final action" skills/finishing-work/SKILL.md`
Expected: one match, in the Red Flags **Always** list.

- [ ] **Step 5: Commit**

```bash
git add skills/finishing-work/SKILL.md
git commit -m "feat: finishing-work deletes the scratch execution handoff

Add a final cleanup step that runs 'rm -f .superpowers/execution-handoff.md'
once all checks pass and the tree is clean, so the handoff doc never
persists after a completed execution. Idempotent via rm -f so it's a
no-op for repos that never generated a handoff."
```