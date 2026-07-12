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

Read `.superpowers/execution-handoff.md` — the single, fixed, gitignored scratch path where `writing-plans` always writes the most recent handoff.

- **Handoff doc found:** Extract the `**Plan:**` and `**Spec:**` paths from its header. Continue to Step 2.
- **Handoff doc not found:** Ask the user for the plan path. Continue to Step 3 (legacy fallback — no handoff context).

There is exactly one handoff at any time (a new plan overwrites the previous one), so there is never a list to choose from and no name for the user to remember.

### Step 2: Read the Handoff Doc and Plan

Read the handoff doc first — it points to the plan and spec. Then read the plan.

Summarize for the user:
- The feature name
- The number of tasks in the plan
- Any key insights from the handoff's "Planning Insights" section

### Step 3: Present Execution Options

Ask the user which execution skill to use:

1. **subagent-driven-development** — fresh subagent per task, review between tasks (best for mostly independent tasks)
2. **executing-plans** — inline execution with checkpoints

### Step 4: Load the Chosen Skill

Invoke the chosen skill via the `skill` tool. The chosen skill takes over from here — it reads the plan as part of its normal step 1. The handoff doc persists at `.superpowers/execution-handoff.md` through execution and is deleted by `finishing-work` when work completes; this skill does not delete it.

## Red Flags

**Never:**
- Execute tasks yourself — delegate to the chosen execution skill
- Choose the execution skill for the user
- Modify the plan or handoff doc
- Skip the handoff doc when it exists
