# Planning-to-Execution Handoff Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Introduce a handoff document and a new `plan-execution-entry` skill that create a clean context break between the planning phase and the execution phase.

**Architecture:** A new `plan-execution-entry` skill is created. `writing-plans` gains a handoff-doc generation step and a revised handoff message. `executing-plans` and `subagent-driven-development` gain a step to read the handoff doc. `README.md` is updated with the new skill. All changes are markdown files — no code or tests to run.

**Tech Stack:** Markdown skill files, YAML frontmatter.

## Global Constraints

- Skill names use letters, numbers, and hyphens only.
- YAML frontmatter `name` + `description` fields, max 1024 chars total.
- Descriptions start with "Use when..." and describe triggering conditions only, never workflow summary.
- The handoff doc is a Markdown file, not code. No new scripts or plugin tooling.
- The execution skill decision (subagent-driven vs executing-plans) is made by the human user in the execution session, not by the planning session, the handoff doc, or auto-detection.
- Starting a new session is recommended but not enforced. Users who prefer the old single-session flow can ignore the handoff message and load an execution skill directly.
- Backward compatibility: existing plans without handoff docs work unchanged. The execution skills' handoff-reading step is a graceful no-op when no handoff doc exists.

---

### Task 1: Create `plan-execution-entry` skill

**Files:**
- Create: `skills/plan-execution-entry/SKILL.md`

**Interfaces:**
- Produces: a new skill `plan-execution-entry` that `writing-plans` references in its handoff message
- Consumes: `superpowers:subagent-driven-development` and `superpowers:executing-plans` (loaded via the `skill` tool after user choice)

- [ ] **Step 1: Create the skill directory and file**

Create `skills/plan-execution-entry/SKILL.md` with this exact content:

```markdown
---
name: plan-execution-entry
description: Use at the start of a new session to execute a written implementation plan - reads the handoff and plan, asks the user which execution skill to use, then loads it
---

# Plan Execution Entry

## Overview

The entry point for a new session executing a plan. Discovers the handoff doc and plan, presents execution options to the user, loads the chosen skill.

**Core principle:** Discover → present options → delegate. This skill does not execute tasks itself.

**Announce at start:** "I'm using the plan-execution-entry skill to set up execution."

## The Process

### Step 1: Find the Handoff Doc

If the user's prompt includes a plan path (e.g., `docs/superpowers/plans/YYYY-MM-DD-feature.md`), look for the handoff doc at the same path with `-handoff` suffix (e.g., `docs/superpowers/plans/YYYY-MM-DD-feature-handoff.md`).

- **Handoff doc found:** Use it. Continue to Step 2.
- **Handoff doc not found at that path:** Ask the user for the plan path. Continue to Step 3 (legacy flow — no handoff doc).
- **No plan path in the prompt:** Scan `docs/superpowers/plans/` for `*-handoff.md` files.
  - Exactly one found: use it.
  - Multiple found: list them with timestamps and ask the user which one to use.
  - None found: ask the user for the plan path. Continue to Step 3 (legacy flow — no handoff doc).

### Step 2: Read the Handoff Doc and Plan

Read the handoff doc first — it points to the plan and spec. Then read the plan.

Summarize for the user:
- The feature name
- The number of tasks in the plan
- Any key insights from the handoff's "Planning Insights" section

### Step 3: Present Execution Options

Show the two execution options to the user:

> Two execution skills are available:
> 1. **subagent-driven-development** — fresh subagent per task, review between tasks (best for mostly independent tasks)
> 2. **executing-plans** — inline execution with checkpoints
>
> Which would you like to use?

Wait for the user's choice. Do not auto-select. Do not recommend one over the other.

### Step 4: Load the Chosen Skill

Invoke the chosen skill via the `skill` tool. The chosen skill takes over from here — it reads the plan (and handoff doc if present) as part of its normal step 1.

## Does NOT Do

- Does not execute any tasks itself.
- Does not choose the execution skill for the user.
- Does not modify the plan or handoff doc.
- Does not dispatch subagents.

## Common Mistakes

### Auto-selecting an execution skill
- **Problem:** The user should decide based on their environment and preferences
- **Fix:** Present both options neutrally and wait for the user's choice

### Skipping the handoff doc
- **Problem:** The handoff doc carries planning context that helps with judgment calls during execution
- **Fix:** Always read the handoff doc when it exists before presenting options

### Reading the plan before the handoff doc
- **Problem:** The handoff doc points to the plan and spec; reading it first gives context for the plan
- **Fix:** Read handoff doc first, then plan

## Red Flags

**Never:**
- Execute tasks yourself — delegate to the chosen execution skill
- Choose the execution skill for the user
- Modify the plan or handoff doc
- Skip the handoff doc when it exists
```

- [ ] **Step 2: Verify the file was created correctly**

Run: `head -5 skills/plan-execution-entry/SKILL.md`
Expected: YAML frontmatter with `name: plan-execution-entry` and the description line.

Run: `wc -l skills/plan-execution-entry/SKILL.md`
Expected: ~85-95 lines.

- [ ] **Step 3: Verify frontmatter constraints**

Run: `node -e "const fs=require('fs');const c=fs.readFileSync('skills/plan-execution-entry/SKILL.md','utf8');const m=c.match(/---\n([\s\S]*?)\n---/);const fm=m[1];const lines=fm.split('\n');let len=0;for(const l of lines){len+=l.length+1}console.log('frontmatter chars:',len);const name=fm.match(/name:\s*(.+)/);const desc=fm.match(/description:\s*(.+)/);console.log('name:',name[1]);console.log('desc starts with Use:',desc[1].startsWith('Use'));"`
Expected: frontmatter chars under 1024, name is `plan-execution-entry`, desc starts with `Use`.

- [ ] **Step 4: Commit**

```bash
git add skills/plan-execution-entry/SKILL.md
git commit -m "feat: add plan-execution-entry skill

New skill that serves as the entry point for a new session
executing a plan. Reads the handoff doc and plan, asks the user
which execution skill to use, then loads it."
```

---

### Task 2: Update `writing-plans` skill

**Files:**
- Modify: `skills/writing-plans/SKILL.md:144-174`

**Interfaces:**
- Consumes: the handoff doc template (defined inline below)
- Produces: handoff docs alongside plans; references `plan-execution-entry` in the handoff message

- [ ] **Step 1: Add the "Handoff Document" section after Self-Review**

In `skills/writing-plans/SKILL.md`, after the "Self-Review" section (which ends at line 154 with the text "If you find a spec requirement with no task, add the task.") and before the "Execution Handoff" section (line 156), insert this new section:

```markdown
## Handoff Document

After the plan and self-review are complete, generate a handoff document alongside the plan. This carries the "why" and "watch out for" context that the spec and plan don't capture — the planning orchestrator's distilled summary of what it learned, not a transcript.

**Save to:** `docs/superpowers/plans/YYYY-MM-DD-<feature>-handoff.md` (same naming convention as the plan, with `-handoff` suffix).

**Template:**

````markdown
# [Feature Name] — Planning Handoff

> This document bridges planning and execution. Read this first, then the plan.

**Plan:** docs/superpowers/plans/YYYY-MM-DD-<feature>.md
**Spec:** docs/superpowers/specs/YYYY-MM-DD-<feature>-design.md

## Key Decisions

[3-7 bullet points: the non-obvious choices made during planning and why.
Each decision gets one line on what was chosen and one on why.]

## Rejected Alternatives

[2-5 entries: approaches considered and rejected, with a one-line reason.
Prevents the execution session from re-deriving paths already ruled out.]

## Planning Insights

[Context the spec and plan don't capture: gotchas discovered during
codebase exploration, fragile areas to watch, implicit assumptions,
environment quirks. Prose, not steps.]

## Execution

Two execution skills are available — choose one and start a new session:

1. **superpowers:subagent-driven-development** — dispatches a fresh
   subagent per task with review between tasks. Best for plans with
   mostly independent tasks.
2. **superpowers:executing-plans** — executes tasks inline in the
   current session with checkpoints.

Start a new session and give it a prompt like:
"Read the handoff at [path]. I want to use [chosen skill] to execute
the plan at [plan path]."
````

**Generation:** Distill this from the planning conversation. The handoff doc is always written after the plan is finalized. If the plan is revised, regenerate the handoff doc.
```

- [ ] **Step 2: Replace the "Execution Handoff" section**

In `skills/writing-plans/SKILL.md`, replace the entire "Execution Handoff" section (currently lines 156-174) with this new content:

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

- [ ] **Step 3: Verify the changes**

Run: `grep -n "Handoff Document" skills/writing-plans/SKILL.md`
Expected: one match, the new section heading.

Run: `grep -n "Execution Handoff" skills/writing-plans/SKILL.md`
Expected: one match, the replaced section heading.

Run: `grep -n "plan-execution-entry" skills/writing-plans/SKILL.md`
Expected: one match, in the Execution Handoff section.

Run: `grep -n "Subagent-Driven (recommended)" skills/writing-plans/SKILL.md`
Expected: no output (old handoff text removed).

- [ ] **Step 4: Commit**

```bash
git add skills/writing-plans/SKILL.md
git commit -m "feat: add handoff doc generation to writing-plans skill

Generate a handoff document alongside the plan that captures key
decisions, rejected alternatives, and planning insights. Replace
the execution handoff section with a message recommending a new
session for execution via the plan-execution-entry skill."
```

---

### Task 3: Update execution skills and README references

**Files:**
- Modify: `skills/executing-plans/SKILL.md:18-22`
- Modify: `skills/subagent-driven-development/SKILL.md:63,68,85-99`
- Modify: `README.md:52,54-60,76-83`

**Interfaces:**
- Consumes: the `plan-execution-entry` skill from Task 1 and the handoff doc format from Task 2

- [ ] **Step 1: Update `skills/executing-plans/SKILL.md` Step 1**

In `skills/executing-plans/SKILL.md`, the current Step 1 (lines 18-22) reads:

```markdown
### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Create todos for the plan items and proceed
```

Change it to:

```markdown
### Step 1: Load and Review Plan
1. Read plan file
2. If a handoff doc exists alongside the plan (same path with `-handoff` suffix), read it before reviewing. The handoff doc's Key Decisions, Rejected Alternatives, and Planning Insights sections provide context for judgment calls when the plan hits blockers or needs adaptation.
3. Review critically - identify any questions or concerns about the plan
4. If concerns: Raise them with your human partner before starting
5. If no concerns: Create todos for the plan items and proceed
```

- [ ] **Step 2: Update `skills/subagent-driven-development/SKILL.md`**

In `skills/subagent-driven-development/SKILL.md`, the process flowchart (lines 47-83) has a node declaration at line 63 and an edge at line 68:

```dot
    "Read plan, note context and global constraints, create todos" [shape=box];
```

and

```dot
    "Read plan, note context and global constraints, create todos" -> "Dispatch implementer subagent (./implementer-prompt.md)";
```

Add a new node declaration after line 63 (after the `"Read plan..."` node declaration):

```dot
    "Read handoff doc if it exists alongside plan" [shape=box];
```

Change the edge at line 68 from:

```dot
    "Read plan, note context and global constraints, create todos" -> "Dispatch implementer subagent (./implementer-prompt.md)";
```

to:

```dot
    "Read plan, note context and global constraints, create todos" -> "Read handoff doc if it exists alongside plan";
    "Read handoff doc if it exists alongside plan" -> "Dispatch implementer subagent (./implementer-prompt.md)";
```

Then, in the prose section, insert a new "Handoff Document" section between the "Pre-Flight Plan Review" section (ends at line 97) and the "Model Selection" section (starts at line 99):

```markdown
## Handoff Document

After reading the plan and before dispatching the first implementer, check for a handoff doc alongside the plan (same path with `-handoff` suffix). If it exists, read it. The handoff doc's Key Decisions, Rejected Alternatives, and Planning Insights sections provide context for judgment calls when the plan hits blockers or needs adaptation. Note any insights relevant to the tasks you're about to dispatch.
```

- [ ] **Step 3: Update `README.md` workflow description (line 52 and after line 54)**

In `README.md`, the current workflow step 3 (line 52) reads:

```markdown
3. **writing-plans** - Activates with approved design. Breaks work into bite-sized tasks (2-5 minutes each). Every task has exact file paths, complete code, verification steps.
```

Change it to:

```markdown
3. **writing-plans** - Activates with approved design. Breaks work into bite-sized tasks (2-5 minutes each). Every task has exact file paths, complete code, verification steps. Generates a handoff document with key decisions and planning insights.
```

After the current step 4 (line 54), insert a new step:

```markdown
5. **plan-execution-entry** - In a new session, reads the handoff and plan, asks the user which execution skill to use, and loads it.
```

Renumber the subsequent steps: the old step 5 (test-driven-development, line 56) becomes 6, step 6 (requesting-code-review, line 58) becomes 7, step 7 (finishing-work, line 60) becomes 8.

- [ ] **Step 4: Update `README.md` skills listing (lines 76-83)**

In `README.md`, the skills listing under **Collaboration** (lines 76-83) currently reads:

```markdown
- **brainstorming** - Socratic design refinement
- **writing-plans** - Detailed implementation plans
- **executing-plans** - Batch execution with checkpoints
- **requesting-code-review** - Pre-review checklist
- **receiving-code-review** - Responding to feedback
- **preparing-workspace** - Clean workspace and baseline test verification
- **finishing-work** - Final checks, spec sync, and commit completeness verification
- **subagent-driven-development** - Fast iteration with two-stage review (spec compliance, then code quality)
```

Add `plan-execution-entry` after `writing-plans`:

```markdown
- **brainstorming** - Socratic design refinement
- **writing-plans** - Detailed implementation plans
- **plan-execution-entry** - New-session entry point for plan execution
- **executing-plans** - Batch execution with checkpoints
- **requesting-code-review** - Pre-review checklist
- **receiving-code-review** - Responding to feedback
- **preparing-workspace** - Clean workspace and baseline test verification
- **finishing-work** - Final checks, spec sync, and commit completeness verification
- **subagent-driven-development** - Fast iteration with two-stage review (spec compliance, then code quality)
```

- [ ] **Step 5: Verify the changes**

Run: `grep -n "handoff doc" skills/executing-plans/SKILL.md`
Expected: one match in Step 1.

Run: `grep -n "Handoff Document" skills/subagent-driven-development/SKILL.md`
Expected: one match, the new section heading.

Run: `grep -n "plan-execution-entry" README.md`
Expected: two matches — one in the workflow section, one in the skills listing.

Run: `grep -n "handoff document" README.md`
Expected: one match in the workflow description for writing-plans.

- [ ] **Step 6: Verify no stale references remain**

Run: `rg 'Subagent-Driven \(recommended\)' --type md -g '!docs/superpowers/**'`
Expected: no output (old writing-plans handoff text removed from live skill files; historical plan docs under `docs/superpowers/` are archived and excluded).

- [ ] **Step 7: Commit**

```bash
git add skills/executing-plans/SKILL.md skills/subagent-driven-development/SKILL.md README.md
git commit -m "refactor: add handoff doc reading to execution skills

Update executing-plans and subagent-driven-development to read the
handoff doc alongside the plan when it exists. Update README with
the new plan-execution-entry skill and handoff doc generation in
the writing-plans workflow step."
```
