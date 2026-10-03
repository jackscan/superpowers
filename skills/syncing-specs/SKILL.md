---
name: syncing-specs
description: Use when a plan's implementation is complete, before Finish, and the project maintains canonical capability specs in `docs/specs/` — validates the change's delta specs, merges them into the canonical specs in `docs/specs/`, and archives the change under `docs/specs/changes/archive/`.
---

## Project Check

Does `docs/specs/` exist? No → print "no spec lifecycle in this project; skipping" (one line) and stop. Never create `docs/specs/` — adopting canonical specs is a deliberate decision by your human partner, not a side effect of this skill.

## Resolve the Change

Read the plan's `**Spec:**` field → take the design-doc filename, drop the trailing `-design` suffix → stem → locate `docs/specs/changes/<stem>/`. Fallback: use the plan's own stem; then look for a single active change whose design doc matches. Already archived (present under `docs/specs/changes/archive/`) or no delta dir → print "nothing to merge" and stop cleanly. Multiple candidates → stop and ask your human partner which change applies. `changes` is a reserved capability name; a main spec never lives at `docs/specs/changes/spec.md`.

## Reconcile

Read the execution ledger's `Ruling:` lines and the final review. Where implementation legitimately changed behavior compared to the delta, update the delta first — the delta records what the change *does*, not what it intended. Surface all rulings that changed behavior in the merge report.

## Validate

Re-run the ten grammar rules over every delta file:

1. Every `### Requirement:` sits under one of the four operation sections (`## ADDED Requirements`, `## MODIFIED Requirements`, `## REMOVED Requirements`, `## RENAMED Requirements`).
2. Scenarios use exactly `#### Scenario:` — three hashtags fail silently.
3. Every ADDED/MODIFIED requirement has ≥1 scenario; REMOVED needs only `Reason` + `Migration`; RENAMED pairs each `FROM:` with exactly one `TO:`, in order.
4. The same requirement name may not appear in two sections.
5. Requirement text carries SHALL or MUST and stays ≤500 chars (MODIFIED may not be trimmed to satisfy the limit).
6. MODIFIED carries the complete replacement block.
7. `## Purpose` appears only for a capability with no existing main spec.
8. When RENAMED entries exist, MODIFIED refers to the new name.
9. `#` lines inside fenced code blocks are content, not structure.
10. The capability path must match an exact existing capability (MODIFIED/REMOVED/RENAMED) or name a deliberate new one (ADDED).

A delta at `.../specs/spec.md` (no capability folder), an unpaired `FROM:` / `TO:`, a name in two sections, a MODIFIED/RENAMED on a nonexistent capability, a missing scenario, or all operation sections empty → fix before merging. A main spec that doesn't match the canonical shape → stop and fix (with your human partner if needed) before merging into it.

## Merge (RENAMED → REMOVED → MODIFIED → ADDED)

Process each capability in fixed order. Match requirements by exact name — case- and whitespace-sensitive. A near-miss (case/whitespace-folded match) means stop and check for a typo; never auto-match.

**RENAMED** — source block present and target name absent: rewrite the header line in place; position and content preserved; chains are legal. Target already exists → stop. Source absent and target present → already applied, skip. Both absent → stop.

**REMOVED** — block present: delete the whole block (scenarios go with it; `Reason` + `Migration` were required at authoring). Block absent: warn and treat as already removed.

**MODIFIED** — block present: apply the scenario-loss guard (see below), then replace the whole block. Block absent: stop (likely a typo or a missing RENAMED — check the name and any `FROM:` / `TO:` entries).

**ADDED** — name already present: byte-identical → skip; differs → stop (it is a MODIFIED or a conflict). Absent: append at the end of `## Requirements`; existing order is preserved and all genuinely new requirements land at the end.

**Scenario-loss guard (scenario-loss).** Before replacing a MODIFIED block, compare every `#### Scenario:` the current spec block carries against the delta block, by name and multiplicity. Any current scenario the delta lacks → stop: copy the omitted scenarios into the delta block (or reconcile with your human partner if the omission is intentional). A current block whose text the delta was evidently not based on (a concurrent change landed text the delta doesn't reflect) → stop and reconcile. The merge never silently drops a scenario.

## New Capability

Main spec absent: only ADDED is legal (MODIFIED/RENAMED → stop; REMOVED → warn and ignore). Create the skeleton `# <capability> Specification` / `## Purpose` (copied verbatim from the delta's `## Purpose`; missing → `TBD - created by change <change-id>`, flagged to your human partner) / `## Requirements`, then apply ADDED.

## Retirement

A delta that removes the last requirement of a capability → stop and ask your human partner before deleting the main spec file. On approval: delete `docs/specs/<capability>/spec.md` and prune empty parent dirs; the Purpose goes with it and the report names it.

## Verify

Re-read every main spec touched during this merge: no delta headers (`## ADDED Requirements`, `## MODIFIED Requirements`, `## REMOVED Requirements`, `## RENAMED Requirements`) leaked in, shape is canonical (`# … Specification` / `## Purpose` / `## Requirements`), ≥1 requirement each with ≥1 scenario, no duplicate requirement names, existing order preserved, file ends with a single newline.

## Archive

`docs/specs/changes/archive/` exists — create if needed. Move the whole change directory (`git mv` when tracked). Idempotence: a change already in `archive/` is already merged — skip.

## Report and Commit

For each capability: `+N added, ~M modified, -R removed, →K renamed`; files written; everything skipped and why; rulings that changed behavior. Commit merged specs and the archive move together.
