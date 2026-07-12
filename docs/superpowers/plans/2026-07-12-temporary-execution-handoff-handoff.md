# Temporary, Unambiguous Execution Handoff — Planning Handoff

> This document bridges planning and execution. Read this first, then the plan.

**Plan:** docs/superpowers/plans/2026-07-12-temporary-execution-handoff.md
**Spec:** docs/superpowers/specs/2026-07-12-temporary-execution-handoff-design.md

## Key Decisions

- **Single fixed scratch path `.superpowers/execution-handoff.md`** — overwriting on each new plan. Chosen because it makes the handoff unambiguous to find (no scanning, no listing, no name for the user to remember) and keeps it out of git via the already-gitignored `.superpowers/` dir.
- **Cleanup at completion, not at first read** — `finishing-work` deletes the scratch handoff as its final step. Chosen so a crashed/restarted execution session can re-read the same handoff and resume; deleting at first read would lose that recovery property.
- **Start prompt collapses to "Load the plan-execution-entry skill."** — no plan path. Chosen because the handoff itself carries the plan path; asking the user to supply it reintroduces the friction the handoff was meant to eliminate.
- **Drop the scan / multi-handoff branches in `plan-execution-entry`** — replaced by one read + a clean ask-for-plan-path fallback. Chosen because the scan and multi-handoff branches were the source of the ambiguity this design removes; keeping them as fallbacks would reintroduce it.
- **No README change** — current wording stays accurate. Chosen because the README never exposes a path or filename; the storage-model change is invisible to it.
- **Keep the legacy fallback (ask for plan path when the scratch handoff is absent)** — covers repos that never generated a handoff, executing old plans, or post-cleanup re-runs. Chosen for backward compatibility without re-adding the scan.

## Rejected Alternatives

- **Delete the handoff immediately after `plan-execution-entry` reads it** — rejected because a crashed/restarted session would find nothing and lose all planning context; deleting at completion preserves resume-ability.
- **Keep per-plan handoff files but move them under `.superpowers/handoffs/`** — rejected because multiple files still create ambiguity (which one to execute) and require the user to remember a name; the single-fixed-path model is strictly simpler.
- **Embed the handoff as a section inside the plan file, stripped by `finishing-work`** — rejected because it pollutes the plan doc mid-execution and complicates the plan's own structure; a separate scratch file keeps the plan clean.
- **Re-add the `*-handoff.md` suffix scan as a fallback for old handoffs** — rejected because it reintroduces the multi-handoff ambiguity; old plans are handled by the manual plan-path fallback instead.
- **No fallback (error if the scratch handoff is absent)** — rejected for being too strict; breaks backward compat and executing legacy plans.

## Planning Insights

- **This handoff is the LAST one written to the permanent path.** The `writing-plans` skill (as it exists *now*, while this plan is being written) saves handoffs to `docs/superpowers/plans/YYYY-MM-DD-<feature>-handoff.md`. Task 1 of this plan changes that to `.superpowers/execution-handoff.md`. So this very handoff sits at the old permanent path; every plan written *after* this one is executed will use the new scratch path. You do not need to migrate or delete this file — it's a one-time historical artifact of the transition. (The new `finishing-work` cleanup only deletes the new-path file.)

- **`.superpowers/` is already gitignored.** No `.gitignore` changes are needed. Verified: `.gitignore` line 3 lists `.superpowers/`. Other skills (`sdd/progress.md`, `brainstorm/` mockups) already use this dir as scratch — this design follows the established convention.

- **The three tasks are independent and touch three separate files.** Any execution order works; they don't depend on each other at edit time. The natural order (writing-plans → plan-execution-entry → finishing-work) follows the lifecycle (write → read → delete) but is not required.

- **All verification is `grep`-based.** No plugin code, no tests under `tests/`. Each task verifies its edits landed by grepping for exact strings in the edited skill file. The expected-match / no-output pattern is the only "test" available for skill-instruction changes.

- **Watch the nested code fences in Task 3 Step 1.** The "Replace it with" block contains a nested ```bash fence inside the outer markdown block, plus the renumbered "Step 5: Report Complete" block. Count the fences when editing — the original plan file uses four-backtick fences for outer blocks, but the skill file itself uses plain triple-backtick fences. Edit the *skill file*, not the plan's rendering.

- **`grep -c "Step 4: Report Complete"` must return `0` after Task 3.** This catches the renumber: the old "Step 4: Report Complete" heading moves to "Step 5: Report Complete", and "Step 4" is taken by the new "Delete Scratch Handoff" step. Don't just add the new step — renumber the old one.

- **Do not edit the frontmatter `description` of `plan-execution-entry`.** The current text ("reads the handoff and plan…") still describes the behavior accurately. Task 2 only verifies the frontmatter is unchanged (regression check), it does not edit it.

- **Meta: this plan, when executed, changes the skill that produced it.** That's expected and fine. The next plan written after this one will use the new scratch-path handoff flow and the simplified start prompt. No special handling needed during execution.

## Execution

Two execution skills are available — choose one and start a new session:

1. **superpowers:subagent-driven-development** — dispatches a fresh
   subagent per task with review between tasks. Best for plans with
   mostly independent tasks.
2. **superpowers:executing-plans** — executes tasks inline in the
   current session with checkpoints.

Start a new session and give it a prompt like:
"Read the handoff at docs/superpowers/plans/2026-07-12-temporary-execution-handoff-handoff.md. I want to use [chosen skill] to execute the plan at docs/superpowers/plans/2026-07-12-temporary-execution-handoff.md."