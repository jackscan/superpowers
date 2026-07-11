---
name: plan-execution-entry
description: Use when starting a new session to execute a written implementation plan - reads the handoff and plan, asks the user which execution skill to use, then loads it
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
- **Handoff doc not found at that path:** Proceed to Step 3 using the plan path the user provided (legacy flow — no handoff doc).
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
