# OpenSpec-Style Spec Lifecycle — Design Spec

**Status:** Approved design (brainstormed 2026-10-03); implementation plan to follow.
**Objective:** Extend the superpowers workflow with OpenSpec-style spec maintenance —
a delta spec written at design time, merged into canonical capability specs when
implementation finishes — with the smallest possible diff to existing files, so
upstream superpowers updates stay cheap to merge into this fork.
**Hard invariants:** (1) Existing files change only in the three pointer blocks (plus
two README list lines); all new behavior lives in new files. (2) No new runtime
dependencies, no new scripts — the merge is agent-guided per skill prose. (3)
`docs/specs/` is never created as a side effect; the lifecycle is opt-in per project.
(4) The superpowers repo itself does not adopt it — no `docs/specs/` here, deliberate.

## Source

The behavior model is Fission-AI/OpenSpec v1.14.0, documented in
`openspec-spec-lifecycle-report.md` (repo root, deliberately untracked — a local
reference copy, not part of the repo): two spec kinds joined by capability
path; the delta grammar; the fixed-order merge; whole-block MODIFIED; the
scenario-loss guard; the validation gate; the archive step. Section references of the
form §N below cite that report. Nothing here shells out to or depends on the
`openspec` CLI — this is a port of the *lifecycle*, sized to superpowers.

## Design Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | The delta is written after the design doc, before the user review gate; the gate reviews design doc + delta together. | Partner's call. One approval gate covers both artifacts; writing-plans and every downstream reviewer then hold an approved behavioral contract. |
| 2 | Agent-guided merge — OpenSpec's own `openspec-sync-specs` model — with no scripts. | Partner's call (approach B over a deterministic script port and a hybrid verifier). Smallest footprint; every safety rail (fixed order, whole-block MODIFIED, scenario-loss guard) lives as a normative prose checklist in `syncing-specs`. Accepted trade-off: no mechanical guard; concurrency detection is prose-based and imperfect (§12.1). |
| 3 | Deltas live in the spec tree: `docs/specs/changes/<change-id>/specs/<capability-path>/spec.md`; after merge the change dir moves whole to `docs/specs/changes/archive/<change-id>/`. | Partner's call. Mirrors OpenSpec's tree rooted at `docs/specs/`; active changes stay visible; the archive retains each change's deltas as history alongside the design doc and plan that live in `docs/superpowers/`. |
| 4 | Activation = the project has a `docs/specs/` directory. Never created as a side effect. | OpenSpec's "Project check" convention: adopting canonical specs is a deliberate human decision. Explicitly not created in this repo. |
| 5 | `change-id` = design-doc filename minus its `-design` suffix — the stem shared with the plan. `writing-plans` gets zero edits: the plan's `**Spec:**` field already names the design doc, and `syncing-specs` resolves design doc → stem → `docs/specs/changes/<stem>/`. | Plan and design doc share the stem by repo convention; resolution needs no writing-plans change. |
| 6 | The merge hook sits at the end of `## Final Review`, immediately before `## Finish`, in both execution skills — after the final review is clean, before workspace deletion (it consumes the ledger's `Ruling:` lines). | Partner's literal placement ("before `Finish`"). The ledger still exists at that point and dies with the workspace. |
| 7 | `changes` is a reserved capability name; a main spec never lives at `docs/specs/changes/spec.md`. | `docs/specs/changes/` is the change tree; a capability at that path would be ambiguous with it. |
| 8 | Bounded and spike paths produce no deltas; explicit invocation of `writing-spec-deltas` covers a bounded change when wanted. | Partner scoped the hooks to the architectural path (design gate + the two execution skills). YAGNI. |
| 9 | One new test dir, `tests/spec-lifecycle/` (structural bash test), plus a throwaway scratch-project exercise during implementation. No behavioral evals now. | Fork-local use; plugin tests cover non-LLM code, and the only new code here is prose. An upstream PR would demand eval evidence per repo AGENTS.md — noted as a future bar, not met now. |
| 10 | README gains two lines in the Collaboration list; the numbered Basic Workflow list is untouched. | Discoverability without churn — the lifecycle is opt-in per project, not part of the basic flow, and inserting there would renumber seven items. |

## Activation

The lifecycle is active in a project iff `docs/specs/` exists. Both hooks and both new
skills re-check this and skip with at most a one-line note when absent. No step ever
creates `docs/specs/` — not the delta writer, not the merger, not as a side effect of
any other action. Adopting canonical specs (creating the folder, seeding first
capability specs) is a deliberate human decision outside this workflow.

## Artifact Model

Two file kinds, one join key — `<capability-path>` is the directory path relative to
`docs/specs/` (nesting allowed: `user-auth`, `identity/user-auth`), and it is the
*only* join key between a delta and its main spec.

```
docs/specs/
├── <capability-path>/spec.md                 # MAIN spec (canonical, permanent)
└── changes/
    ├── <change-id>/                          # active change
    │   └── specs/<capability-path>/spec.md   # DELTA spec(s), one per capability
    └── archive/
        └── <change-id>/                      # moved whole after merge
```

| | Delta spec | Main spec |
|---|---|---|
| Life | written at design time, archived after merge | permanent source of truth |
| Shape | operation sections (`## ADDED/MODIFIED/REMOVED/RENAMED Requirements`) | `# <capability> Specification` → `## Purpose` → `## Requirements` |
| Role | what this change does to a capability | what the capability does today |

- Active changes are directories directly under `docs/specs/changes/`, excluding
  `archive/` and dot-entries. A delta file must be literally named `spec.md` inside a
  capability folder — a delta at `.../specs/spec.md` (no capability) is invalid, and
  so is any other filename.
- `<change-id>` is the design doc's filename stem: `docs/superpowers/specs/2026-10-03-topic-design.md` → `2026-10-03-topic`. It is already date-prefixed, so the archive
  target is `archive/<change-id>/` verbatim — no second date prefix. User preferences
  (a different change-id named by the partner) win when stated.

## Delta Grammar (normative)

Ported from §4. One delta file per capability per change, written in the exact
OpenSpec grammar:

```markdown
# Spec Delta

## Purpose
<!-- New capabilities ONLY: 50+ chars; seeds the new main spec's Purpose -->

## ADDED Requirements
### Requirement: <name>
<text with SHALL/MUST — one sentence, ≤500 chars>

#### Scenario: <name>
- **WHEN** <condition>
- **THEN** <expected outcome>

## MODIFIED Requirements
### Requirement: <existing name — byte-exact>
<the COMPLETE replacement block: the current block copied whole, then edited>

## REMOVED Requirements
### Requirement: <name>
**Reason**: <why it is being removed>
**Migration**: <what existing behavior/dependents do instead>

## RENAMED Requirements
- FROM: `### Requirement: <Old Name>`
- TO: `### Requirement: <New Name>`
```

Rules, all checked by `writing-spec-deltas` before handoff and re-checked by
`syncing-specs` before merge:

1. Every `### Requirement:` sits under one of the four operation sections; a
   requirement outside all four is an error.
2. Scenarios use exactly four hashtags (`#### Scenario:`) — three fail silently.
   Every `####` line is a scenario, and any heading line ends a requirement
   block, so nothing inside a requirement may use a heading — notes are list
   items or bold text, never `##`/`###`/`####` lines.
3. Every ADDED/MODIFIED requirement has ≥1 scenario; REMOVED needs only
   Reason + Migration; RENAMED is FROM/TO pairs, each FROM paired with exactly one TO,
   in order.
4. The same requirement name may not appear in two sections.
5. Requirement text carries SHALL or MUST and stays ≤500 chars (MODIFIED may not be
   trimmed to satisfy the length check).
6. MODIFIED carries the **complete** replacement block, authored by
   copy-entire-current-block-then-edit; anything the current block has that the delta
   block lacks is *lost* at merge — the scenario-loss guard exists to stop exactly
   this.
7. `## Purpose` appears only for a capability with no existing main spec.
8. When a RENAMED entry exists, MODIFIED refers to the NEW name.
9. `#` lines inside fenced code blocks are content, never structure.
10. The capability path in the delta's location must be an exact existing
    capability (for MODIFIED/REMOVED/RENAMED) or a new one (for ADDED) — a mistyped
    path targets a capability that does not exist rather than the one meant.

## Main Spec Shape (normative)

```markdown
# <capability> Specification

## Purpose
<one or two sentences, 50+ chars>

## Requirements

### Requirement: <name>
<text with SHALL/MUST>

#### Scenario: <name>
- **WHEN** <condition>
- **THEN** <expected outcome>
```

A main spec never contains a delta header (`## ADDED Requirements` etc.), never has
a requirement outside `## Requirements`, never has two requirements with the same
name, always has ≥1 requirement, and each requirement has ≥1 scenario. A delta's
`## Purpose` is copied verbatim into a new main spec's Purpose; once a capability
exists, a delta's `## Purpose` is ignored — changing an existing capability's
Purpose is not covered by the delta grammar. It is a deliberate direct edit to the
main spec, made only when the design doc clearly calls for it, and it is noted in
the merge report.

## Lifecycle and Hooks

1. **Brainstorming (architectural path).** Design doc written → **invoke
   `writing-spec-deltas`** → delta(s) written under
   `docs/specs/changes/<change-id>/specs/…` → the delta joins the design doc in the
   spec self-review and the user review gate → approved → `writing-plans`
   (unchanged). The delta is committed together with the design doc.
2. **Planning.** `writing-plans` unchanged. The plan's `**Spec:**` field names the
   design doc; that is the resolution anchor for step 3.
3. **Execution end (both execution skills).** Final review clean and fixes
   committed → **invoke `syncing-specs`** → reconcile, validate, merge per
   capability, archive the change dir, commit → `## Finish` (rulings list,
   workspace deletion) → `finishing-a-development-branch` — spec updates ride in
   the same branch/PR as the implementation.
4. **Aftermath.** `docs/superpowers/specs/<stem>-design.md`,
   `docs/superpowers/plans/<stem>.md`, and
   `docs/specs/changes/archive/<change-id>/` together are the change's record;
   `docs/specs/<capability>/spec.md` is the living truth.

## Skill: `writing-spec-deltas`

Frontmatter: name `writing-spec-deltas`; description triggers only in projects that
maintain canonical specs — e.g. "Use during brainstorming after a design spec is
written, when the project maintains canonical capability specs in `docs/specs/` —
writes this change's OpenSpec-style delta specs (`docs/specs/changes/…`). Also use
when explicitly requested to spec a bounded change." No `allowed-tools` frontmatter
(house style: none).

Body sections:

- **Project check.** `docs/specs/` exists? No → "no spec lifecycle in this project;
  skipping" (at most one line; never create the folder). Yes → continue.
- **Appropriateness.** Appropriate iff the change alters requirement-level behavior
  of at least one capability: a new capability, or added/modified/removed
  user-visible behavior of an existing one. Pure refactors, tooling-only,
  docs-only → skip with a one-line note. Genuinely unsure → ask the partner.
- **Inventory.** Read `docs/specs/**/spec.md` (excluding the `changes/` tree); capability id = directory path
  relative to `docs/specs/`. Two-pass read like OpenSpec's explore: skim the tree
  (heads and Purpose), then read in full only the capabilities this change plausibly
  touches.
- **Author.** For each affected capability, write
  `docs/specs/changes/<change-id>/specs/<capability-path>/spec.md` per the grammar
  above. MODIFIED blocks are copied from the current main spec *whole* before
  editing. New capability: `## Purpose` (50+ chars) + ADDED only. One file per
  capability; no invented capability paths.
- **Self-validate.** Run the ten grammar rules as a checklist; fix findings inline.
- **Hand off.** Report the delta paths; they join the design doc in brainstorming's
  spec self-review and user review gate; commit together with the design doc.

## Skill: `syncing-specs`

Frontmatter: name `syncing-specs`; description triggers only at implementation end in
lifecycle projects — e.g. "Use when a plan's implementation is complete and the
project maintains canonical specs in `docs/specs/` — validates and merges the
change's delta specs into the canonical specs, then archives the change. Runs at the
end of plan execution, before Finish."

Body sections:

- **Project check + resolve.** `docs/specs/` absent → skip (one line). Resolve the
  change: plan → its `**Spec:**` field → design doc filename minus `-design` →
  `docs/specs/changes/<stem>/`. Fallback: the plan's own stem; then a single active
  change whose design doc matches. Already archived or no delta dir → skip cleanly
  ("nothing to merge"). Multiple candidate changes → stop and ask the partner.
- **Reconcile.** Read the execution ledger's `Ruling:` lines and the final review.
  Where implementation legitimately changed behavior vs the delta, update the delta
  first — the delta records what the change *does*, not what it intended. Rulings
  that changed behavior are surfaced in the merge report.
- **Validate.** Re-run the ten grammar rules over every delta file; a delta at
  `.../specs/spec.md` root, an unpaired FROM/TO, a name in two sections, a
  MODIFIED/RENAMED on a nonexistent capability, a missing scenario, or a delta
  with no operation sections (or all sections empty — nothing to merge, drop
  the file) → fix the delta before merging. A main spec that doesn't match the
  canonical shape → stop and fix it (with the partner if needed) before merging
  into it.
- **Merge, per capability, in order RENAMED → REMOVED → MODIFIED → ADDED.** Match
  requirements by exact name — case- and whitespace-sensitive; a near-miss
  (case/whitespace-folded match) means stop and check for a typo, never
  auto-match.

  - **RENAMED** — normal case (source block present, target name absent):
    rewrite the header line in place; position and content preserved; chains are
    legal; case-only renames are legal. Target name already exists → stop.
    Source absent and target present → already applied, skip. Both absent →
    stop.
  - **REMOVED** — block present: delete the whole block (its scenarios go with
    it; Reason + Migration were required at authoring). Block absent: warn and
    treat as already removed.
  - **MODIFIED** — block present: replace the whole block, under the
    scenario-loss guard below. Block absent: stop (likely a typo or a lost
    RENAMED — check the name and any FROM/TO).
  - **ADDED** — name already present: byte-identical → skip; differs → stop (it
    is a MODIFIED or a conflict). Absent: append at the end of `##
    Requirements` — existing order is preserved and all genuinely new
    requirements land at the end.

- **Scenario-loss guard (the one non-negotiable check).** Before replacing a
  MODIFIED block, compare the scenarios the current spec's block has against the
  delta block's, by name and multiplicity. Any current scenario the delta block
  lacks → stop: copy the omitted scenarios into the delta block (or reconcile with
  the partner if the omission is deliberate) — the merge never drops a scenario
  silently. Likewise, a current block whose content the delta was evidently not
  based on (a concurrent change landed text the delta block doesn't know) → stop
  and reconcile. This is the prose substitute for OpenSpec's unimplemented base
  fingerprints (§12.1) — imperfect, and that is approach B's accepted trade-off.
- **New capability.** Main spec absent: only ADDED is legal (MODIFIED/RENAMED →
  stop; REMOVED → warn and ignore). Create the skeleton `# <capability>
  Specification` / `## Purpose` (from the delta's Purpose verbatim; missing →
  `TBD - created by change <change-id>`, flagged to the partner) / `##
  Requirements`, then apply ADDED.
- **Retirement.** A delta that removes the *last* requirement of a capability →
  stop and ask the partner before deleting the main spec file (no
  `retire_capabilities` marker in this workflow; asking is the house-consistent
  gate). On approval: delete `docs/specs/<capability>/spec.md` and prune empty
  parent dirs; the Purpose goes with it and the report names it.
- **Verify.** Re-read every written main spec: no delta headers leaked, shape
  correct, ≥1 requirement each with ≥1 scenario, no duplicate requirement names,
  existing order preserved, file ends with a single newline.
- **Archive.** `docs/specs/changes/archive/` exists (create if needed) → move the
  whole change dir (`git mv` when tracked). Idempotence: a change already in
  `archive/` is already merged — skip.
- **Report and commit.** Per capability: `+N added, ~M modified, -R removed, →K
  renamed`; files written; everything skipped and why; rulings that changed
  behavior. Commit merged specs + archive move together.

## Existing-File Edits (the complete diff surface)

Four files, all additions, no rewording of existing sentences:

1. `skills/brainstorming/SKILL.md` — one block in "After the Design (architectural
   path)", between the Documentation and Spec Self-Review subsections, sketch:

   > **Spec delta (projects that maintain canonical specs):** If the project has a
   > `docs/specs/` directory, invoke superpowers:writing-spec-deltas now — after the
   > design doc is written, before the self-review — to write this change's spec
   > delta. The delta file(s) join the design doc in the spec self-review and in the
   > user review gate, and are committed with it. If `docs/specs/` does not exist,
   > skip: never create it as a side effect.

   Plus one clause in the User Review Gate message — "Please review the spec and its
   delta, if any, …" — so the gate names both artifacts. Checklist and process graph
   untouched (the section body governs).

2. `skills/subagent-driven-development/SKILL.md` — one block at the end of
   `## Final Review`, immediately before `## Finish`, sketch:

   > **Spec sync (projects that maintain canonical specs):** After the final review
   > is clean and its fixes are committed, and before Finish: if the project has a
   > `docs/specs/` directory, resolve this plan's change (its `**Spec:**` design doc
   > → `docs/specs/changes/<stem>/`) and, if it has delta specs, invoke
   > superpowers:syncing-specs to validate, merge them into the canonical specs, and
   > archive the change — before this plan's workspace is deleted (the sync reads the
   > ledger's rulings). No `docs/specs/` or no deltas → skip.

3. `skills/executing-plans/SKILL.md` — the same block, same placement (end of
   `## Final Review`, before `## Finish`).

4. `README.md` — two lines in the Collaboration list under "What's Inside":

   > - **writing-spec-deltas** - OpenSpec-style delta specs at design time (opt-in per project via `docs/specs/`)
   > - **syncing-specs** - Merge delta specs into canonical specs when implementation ends (opt-in per project via `docs/specs/`)

Untouched: `writing-plans`, `finishing-a-development-branch`, both execution skills'
process graphs, all plugin manifests (skills auto-register from directory scan),
`hooks/`, `scripts/`, `index.js`, the Basic Workflow list.

## Out of Scope

- No `docs/specs/` in the superpowers repo (partner's explicit decision); this
  change therefore ships without a dogfood delta — the activation condition failing
  here is the design working as intended.
- Bounded/spike paths produce no deltas (explicit invocation covers them).
- No scripts, no `openspec` CLI, no base fingerprint files (approach B trade-offs).
- No behavioral evals; upstream-PR evaluation evidence is a future bar, not this
  change's.

## Testing and Verification

- `tests/spec-lifecycle/test-skill-structure.sh` (bash, following
  `tests/diagnosing-superpowers/test-skill-structure.sh` precedent): both new
  skills exist with valid frontmatter whose descriptions name `docs/specs`; the
  three pointer anchors are greppable (`superpowers:writing-spec-deltas` in
  brainstorming; `superpowers:syncing-specs` in both execution skills); no delta
  grammar contradictions between the two skills (spot anchors). The anchor checks
  are the fork's real guard: an upstream merge that clobbers a pointer block fails
  the test loudly.
- A throwaway scratch project (under `/tmp/opencode/`) exercised manually during
  implementation: seed `docs/specs/` with one capability; author a delta per
   `writing-spec-deltas` prose; merge per `syncing-specs` prose; verify the
  outcomes that matter — new capability creation with Purpose seeding, MODIFIED
  whole-block replacement, the scenario-loss guard firing on a deliberately partial
  MODIFIED block, a rename preserving position, the retirement stop, archive move.
  Nothing from the scratch project is committed.

## Maintenance Notes

- Upstream superpowers updates: re-run `tests/spec-lifecycle/` after every merge;
  a failed anchor check means the pointer block was clobbered — re-apply the block
  from this spec's sketches.
- The new skills are fork-local until upstreamed. Upstreaming this needs: eval
  evidence per AGENTS.md (the merge is prose, so evals are the only real proof),
  and a maintainers' call on whether an opt-in spec lifecycle belongs in core.
- If the deterministic-merge trade-off ever bites (a silently dropped scenario),
  the upgrade path is the report's §13 port checklist: add
  `skills/syncing-specs/scripts/spec-merge` and thin the skill to a driver — the
  grammar in this spec already specifies its input format.
