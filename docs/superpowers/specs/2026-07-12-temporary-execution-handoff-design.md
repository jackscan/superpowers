# Temporary, Unambiguous Execution Handoff Design

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the planning-to-execution handoff document temporary (not stored permanently in the repo) and unambiguous to find (the user does not need to know its name or the plan's name to start execution).

**Architecture:** The handoff doc moves from a permanent, per-plan file at `docs/superpowers/plans/YYYY-MM-DD-<feature>-handoff.md` to a single, fixed, gitignored scratch path at `.superpowers/execution-handoff.md`. `writing-plans` always writes there, overwriting any previous handoff. `plan-execution-entry` reads exactly that one path — no scanning, no listing, no ambiguity. `finishing-work` deletes it when execution completes. The handoff's internal template (plan/spec paths at the top, Key Decisions, Rejected Alternatives, Planning Insights, Execution sections) is unchanged. The user's start prompt collapses to "Load the plan-execution-entry skill." because the handoff itself carries the plan path.

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
- Backward compatibility: repositories that never generated a handoff (or where `finishing-work` already deleted it) fall back to the user supplying a plan path manually. Existing permanent plan files under `docs/superpowers/plans/` are unaffected.

## Motivation

The previous handoff design (shipped in `2026-07-11-planning-to-execution-handoff`) stores the handoff doc permanently alongside the plan, as `docs/superpowers/plans/YYYY-MM-DD-<feature>-handoff.md`. Two problems follow:

1. **The handoff is not meant to be permanent.** It is consumed once — by `plan-execution-entry` at the start of an execution session — and carries the "why" / "watch out for" context that the spec and plan don't. Once execution begins, that context lives in the orchestrator's session; the file has no ongoing value and shouldn't accumulate as permanent repo content.
2. **Start friction + ambiguity.** To begin execution the user must supply the handoff doc's name (or the plan's name, from which the entry skill derives the `-handoff` suffix). When multiple `*-handoff.md` files exist, the entry skill lists them and asks the user to pick — reintroducing exactly the disambiguation work the handoff was supposed to eliminate.

The fix: one handoff, at one well-known scratch path, overwritten on each new plan, deleted at the end of execution. The user's start prompt no longer carries any path.

## Design

### 1. New Handoff Storage

**Path:** `.superpowers/execution-handoff.md`

**Properties:**

- **Scratch.** Lives under `.superpowers/`, which is already in `.gitignore` (alongside `sdd/`, `brainstorm/`). Never enters git.
- **Single, fixed, overwrite.** Exactly one handoff exists at a time. Every new plan overwrites any previous handoff. There is no per-feature filename.
- **Lifetime.** Written by `writing-plans` as its final step. Consumed by `plan-execution-entry` at the start of a new execution session. Deleted by `finishing-work` as a final cleanup step when execution completes.

**Template (unchanged from the previous design, apart from its location):**

```markdown
# [Feature Name] — Planning Handoff

> This document bridges planning and execution. Read this first, then the plan. It is a temporary scratch file, deleted when execution completes.

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

Start a new session and give it this prompt:
"Load the plan-execution-entry skill."
```

**Generation:** The planning orchestrator writes this file as its final step after the plan is finalized, distilling it from the planning conversation. If the plan is revised, the handoff is regenerated (overwritten) in place.

### 2. `writing-plans` — Path + Prompt Changes

**Handoff Document section:**

- Change `Save to:` from `docs/superpowers/plans/YYYY-MM-DD-<feature>-handoff.md` to `.superpowers/execution-handoff.md`.
- Add one line explaining the storage model: "This is a temporary scratch file, gitignored via `.superpowers/`. It overwrites any previous handoff; exactly one handoff exists at a time. `finishing-work` deletes it when execution completes."
- Update the template blockquote line to reflect that the doc is temporary (see template above).
- The "Generation" note remains, with the additional clause: "writing to the fixed scratch path always overwrites the previous handoff."

**Execution Handoff section:** simplify the start prompt and add the cleanup note. New content:

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

### 3. `plan-execution-entry` — Read One Fixed Path

**Step 1 (Find the Handoff Doc):** collapse the previous three branches (plan path in prompt → suffix lookup; scan `docs/superpowers/plans/` for `*-handoff.md`; list and choose) into a single read with a clean fallback:

1. Read `.superpowers/execution-handoff.md`.
2. **Found:** extract the `**Plan:**` and `**Spec:**` paths from its header. Continue to Step 2.
3. **Not found:** ask the user for the plan path. Continue to Step 3 (legacy fallback — no handoff context).

The previous scan-for-`*-handoff.md` and multiple-handoffs branches are removed entirely — they are no longer reachable and were the source of the ambiguity this design eliminates.

**Step 2:** unchanged in substance. Read the plan (path now comes from the handoff header, not the user's prompt), summarize feature name + task count + Planning Insights.

**Step 3:** unchanged. Present both execution options, let the user pick.

**Step 4:** tweaked wording — the chosen execution skill takes over and reads the plan in its own Step 1. Note explicitly that the handoff persists through execution and is cleaned up later by `finishing-work` (the entry skill does not delete it).

**Frontmatter `description`:** current text ("reads the handoff and plan…") still describes the behavior accurately; no change required. (If the description later proves to mis-trigger on the absence case, it can be tightened, but that's out of scope here.)

### 4. `finishing-work` — Delete the Scratch Handoff

Add an explicit final cleanup action. Implement it as a new short step after Step 3 ("Verify Commit Completeness") and before Step 4 ("Report Complete"):

- Run `rm -f .superpowers/execution-handoff.md`
- The `rm -f` makes it idempotent — a no-op if no handoff exists (e.g. a project that never generated one, or executing a legacy plan without a handoff).

Update the Quick Reference table with a row: "Work complete, tree clean → delete `.superpowers/execution-handoff.md` as the final action." Add a line to Red Flags **Always**: "Delete `.superpowers/execution-handoff.md` as the final action once all checks pass and the tree is clean."

### 5. `README.md` — No Change Required

The current README workflow wording stays accurate:

- Step 3 still says `writing-plans` "Generates a handoff document with key decisions and planning insights."
- Step 4 still says `plan-execution-entry` "reads the handoff and plan, asks the user which execution skill to use, and loads it."

No path or filename is exposed in the README, so the storage-model change is invisible to it. (If desired for discoverability, a future change could mention the scratch path; not required here.)

## Edge Cases

**Crash / restart mid-execution:** `finishing-work` did not run, so the handoff is still present at `.superpowers/execution-handoff.md`. The user re-runs "execute the plan"; `plan-execution-entry` re-reads the handoff and resumes the same feature. This is a real benefit of deleting at completion rather than at first read.

**User abandons a planned feature, plans a new one:** `writing-plans` overwrites `.superpowers/execution-handoff.md` with the new feature's handoff. The next "execute the plan" runs the new feature. Correct, no stale-handoff risk.

**`finishing-work` is skipped (user declares done without the skill):** the handoff lingers, pointing at the most recently completed feature. The next "execute the plan" surfaces that feature's name in the entry summary — the user sees immediately it's already done and aborts. We accept this risk; adding a staleness check (e.g. cross-referencing the SDD progress ledger or `git log`) is out of scope. `finishing-work` is the cleanup gate.

**Old repos / historical `*-handoff.md` files in `docs/superpowers/plans/`:** the entry skill no longer scans for these. They are archived historical artifacts under `docs/superpowers/`. Anyone revisiting an old plan supplies its path manually (legacy fallback). We deliberately do **not** re-add the suffix scan as a fallback — that would reintroduce the multi-handoff ambiguity this design removes.

**Backward compatibility:** existing permanent plan files in `docs/superpowers/plans/` are unaffected. Only the handoff doc changes location and lifetime. Repos that never generated a handoff (or where `finishing-work` already deleted it) get the legacy fallback: the entry asks for a plan path.

**`.superpowers/` not gitignored in some fork:** out of scope — the canonical repo's `.gitignore` already ignores it, and the `brainstorm` skill already instructs users to add `.superpowers/` to `.gitignore`. No new instructions are introduced.

## Testing

Skill-instruction changes only — no plugin code, no new scripts.

1. **Skill description triggering (quick):** verify `plan-execution-entry`'s description still triggers when a user says "execute the plan" in a new session, and does not trigger during planning. The description text is unchanged in this design, so this is a regression check only.

2. **Manual verification (thorough):**
   - After implementation, confirm `skills/writing-plans/SKILL.md` saves the handoff to `.superpowers/execution-handoff.md` and the start prompt is just "Load the plan-execution-entry skill."
   - Confirm `skills/plan-execution-entry/SKILL.md` reads that exact path with a clean "ask for plan path" fallback, and contains no remaining `*-handoff.md` scan or multi-handoff branch.
   - Confirm `skills/finishing-work/SKILL.md` deletes the scratch handoff after the clean-tree check.
   - Confirm `.gitignore` already covers `.superpowers/` (it does — no change).

No new bash/node tests under `tests/`.

## Files Touched

| File | Action |
|------|--------|
| `skills/writing-plans/SKILL.md` | Edit Handoff Document section (save path + storage note) and Execution Handoff section (simplified start prompt + cleanup note) |
| `skills/plan-execution-entry/SKILL.md` | Edit Step 1 to read `.superpowers/execution-handoff.md` or fall back to asking for the plan path; remove scan/multi-handoff branches; tweak Step 4 wording |
| `skills/finishing-work/SKILL.md` | Add final cleanup step deleting `.superpowers/execution-handoff.md`; update Quick Reference and Red Flags |
| `README.md` | No change required (current wording stays accurate) |