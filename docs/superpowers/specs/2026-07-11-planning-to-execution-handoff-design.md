# Planning-to-Execution Handoff Design

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Introduce a clean context break between the planning phase (brainstorming + writing-plans) and the execution phase (subagent-driven-development or executing-plans) by generating a handoff document and starting a fresh session for execution.

**Architecture:** Two changes to the skill library. `writing-plans` gains a handoff-doc generation step and a revised handoff message. A new `plan-execution-entry` skill serves as the entry point for the new session — it discovers the handoff doc and plan, reads the handoff, asks the user which execution skill to use, and loads it. The execution skills (`executing-plans`, `subagent-driven-development`) are unchanged — they read the plan as they do today. `plan-execution-entry` is the sole reader of the handoff doc. No plugin code changes.

**Tech Stack:** Markdown skill files, YAML frontmatter.

## Global Constraints

- Skill names use letters, numbers, and hyphens only.
- YAML frontmatter `name` + `description` fields, max 1024 chars total.
- Descriptions start with "Use when..." and describe triggering conditions only, never workflow summary.
- The handoff doc is a Markdown file, not code. No new scripts or plugin tooling.
- The execution skill decision (subagent-driven vs executing-plans) is made by the human user in the execution session, not by the planning session, the handoff doc, or auto-detection.
- Starting a new session is recommended but not enforced. Users who prefer the old single-session flow can ignore the handoff message and load an execution skill directly.
- Backward compatibility: existing plans without handoff docs work unchanged. `plan-execution-entry` falls back to asking for the plan path directly when no handoff doc is found.

## Motivation

The planning phase (brainstorming + writing-plans) accumulates substantial context in the orchestrator's session: codebase exploration, design discussions, rejected alternatives, spec iteration. When the orchestrator transitions to execution, this planning context remains resident but is largely unnecessary for execution coordination. The `subagent-driven-development` skill already addresses per-task context isolation (fresh subagents, file-based artifacts, progress ledger), but the orchestrator's own session still carries the full planning conversation into the execution phase.

The current `writing-plans` skill's "Execution Handoff" section offers two execution paths and implicitly assumes the user stays in the same session. There is no mechanism to shed planning context before execution begins. This design introduces that mechanism: a handoff document that captures the planning-phase knowledge worth preserving, and a clean session break so the execution orchestrator starts with just the plan, spec, and handoff context.

## Design

### 1. Handoff Document

**Location:** `docs/superpowers/plans/YYYY-MM-DD-<feature>-handoff.md` — alongside the plan, same naming convention with `-handoff` suffix.

**Purpose:** Carries the "why" and "watch out for" context that the spec (what to build) and plan (how to build it) don't capture. This is the planning orchestrator's distilled summary of what it learned, not a transcript.

**Template:**

```markdown
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
```

**Generation:** The planning orchestrator writes this as a final step after the plan self-review, distilling it from the planning conversation. It is always written after the plan is finalized. If the plan is revised, the handoff doc is regenerated.

### 2. `writing-plans` — Handoff Generation + Revised Handoff Message

**Current state:** The "Execution Handoff" section (lines 157-174 of `skills/writing-plans/SKILL.md`) offers two execution options and hands off within the same session:

```
1. Subagent-Driven (recommended) - I dispatch a fresh subagent per task...
2. Inline Execution - Execute tasks in this session...
```

**Changes:**

1. **Add a "Handoff Document" step** after the "Self-Review" section and before the "Execution Handoff" section. This step instructs the agent to generate the handoff doc using the template above, distilling key decisions, rejected alternatives, and planning insights from the planning conversation.

2. **Replace the "Execution Handoff" section** with a new message that:
   - Tells the user the plan and handoff doc are saved
   - Recommends starting a new session for execution (to shed planning context)
   - Tells the user to load `superpowers:plan-execution-entry` in the new session, pointing it at the handoff doc
   - Notes that staying in the current session is also possible (user loads an execution skill directly), but the new-session path is recommended for context efficiency

**New "Execution Handoff" section text:**

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

### 3. NEW Skill: `plan-execution-entry`

**Purpose:** The entry point for a new session executing a plan. Discovers the handoff doc and plan, presents execution options to the user, loads the chosen skill.

**Frontmatter:**
```yaml
name: plan-execution-entry
description: Use when starting a new session to execute a written implementation plan - reads the handoff and plan, asks the user which execution skill to use, then loads it
```

**Skill file:** `skills/plan-execution-entry/SKILL.md`

**Process:**

1. **Find the handoff doc.** If the user's prompt includes a plan path (e.g., `docs/superpowers/plans/YYYY-MM-DD-feature.md`), look for the handoff doc at the same path with `-handoff` suffix (e.g., `docs/superpowers/plans/YYYY-MM-DD-feature-handoff.md`). If found, use it. If not found, ask the user for the plan path and proceed to step 3 (legacy flow — no handoff doc). If the user did not provide a plan path, scan `docs/superpowers/plans/` for `*-handoff.md` files. If exactly one exists, use it. If multiple exist, list them with timestamps and ask the user which one to use. If none exist, ask the user for the plan path and skip to step 3.

2. **Read the handoff doc and plan.** Read the handoff doc first (it points to the plan and spec). Then read the plan. Summarize: the feature name, the number of tasks, and any key insights from the handoff's "Planning Insights" section.

3. **Present execution options to the user.** Show the two options from the handoff doc's "Execution" section:

   > Two execution skills are available:
   > 1. **subagent-driven-development** — fresh subagent per task, review between tasks (best for mostly independent tasks)
   > 2. **executing-plans** — inline execution with checkpoints
   >
   > Which would you like to use?

   Wait for the user's choice. Do not auto-select. Do not recommend one over the other.

4. **Load the chosen skill.** Invoke the chosen skill via the `skill` tool. The chosen skill takes over from here — it reads the plan as part of its normal step 1. (The handoff doc's planning context was already consumed in Step 2; execution skills do not re-read it.)

**Does NOT do:**
- Does not execute any tasks itself.
- Does not choose the execution skill for the user.
- Does not modify the plan or handoff doc.
- Does not dispatch subagents.

**Announce at start:** "I'm using the plan-execution-entry skill to set up execution."

### 4. Execution Skills — Unchanged

`executing-plans` and `subagent-driven-development` are **not modified** by this design. They read the plan as they do today. The handoff doc is read only by `plan-execution-entry` (Step 2), whose planning context is consumed at routing time and not re-read by the execution skill it loads.

Rationale: the handoff doc exists to carry planning context across a session break. The entry skill is the bridge. Duplicating the read in the execution skills adds steps that the primary (entry-skill) path doesn't need.

**Trade-off:** users who bypass `plan-execution-entry` (loading an execution skill directly, or staying in the planning session) are responsible for reading the handoff doc themselves if they want its planning context. The entry skill is a convenience, not a gate — but it's the convenience that makes the handoff doc useful.

### 5. Reference Updates

| File | Changes |
|------|---------|
| `README.md` | Add `plan-execution-entry` to the skills listing with its one-line description. Update the workflow description to mention the handoff doc generation and new-session recommendation. |
| `skills/writing-plans/SKILL.md` | Add "Handoff Document" step after Self-Review. Replace "Execution Handoff" section with the new handoff message. |
| `skills/plan-execution-entry/SKILL.md` | Create (new skill). |

## Edge Cases

**Missing handoff doc:** `plan-execution-entry` falls back to asking the user for the plan path directly and proceeds to present execution options. Existing plans written before this change still work — the execution skills read the plan as they do today.

**Multiple handoff docs:** `plan-execution-entry` lists all `*-handoff.md` files with their timestamps and asks the user which one to use.

**User bypasses the entry skill:** A user who knows which execution skill they want can load `subagent-driven-development` or `executing-plans` directly and point at the plan. This is fully supported — the entry skill is a convenience, not a gate. The handoff doc's planning context is not read in this flow; the user is responsible for reading it themselves if they want it.

**User stays in the same session:** A user who prefers the old flow can ignore the handoff message and load an execution skill directly. The handoff doc is generated but not read. No penalty for not starting a new session — the context cost is the user's to bear.

**Handoff doc goes stale:** If the plan is revised after the handoff doc is written (e.g., the user iterates on the plan in the planning session), `writing-plans` regenerates the handoff doc as part of any plan revision. The handoff doc is always the last thing written.

## Testing

This change is purely skill-instruction changes — no plugin code. Two testing approaches:

1. **Skill description triggering (quick):** Verify that `plan-execution-entry`'s description triggers correctly when a user says "execute the plan" in a new session, and doesn't trigger during planning. Check via the eval harness's triggering tests.

2. **Skill behavior evals (thorough but slow):** Scenarios in `evals/scenarios/` that verify:
   - `writing-plans` generates a handoff doc with all four sections after the plan
   - `plan-execution-entry` discovers the handoff, reads it, presents both options, and loads the chosen skill

No new plugin code means no new bash/node tests in `tests/`.

## Files Touched

| File | Action |
|------|--------|
| `skills/plan-execution-entry/SKILL.md` | Create |
| `skills/writing-plans/SKILL.md` | Edit (add handoff doc step, replace execution handoff section) |
| `README.md` | Edit (add new skill to listing, update workflow description) |
