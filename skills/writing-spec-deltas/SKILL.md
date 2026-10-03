---
name: writing-spec-deltas
description: Use when a design spec has been written during brainstorming and the project maintains canonical capability specs in `docs/specs/` — writes this change's OpenSpec-style delta specs under `docs/specs/changes/`. Also use when your human partner explicitly asks for a delta spec on a bounded change.
---

## Project Check

Check whether `docs/specs/` exists in the project root. If it does not, note: "no spec lifecycle in this project; skipping." Never create `docs/specs/` — adopting canonical specs is a deliberate decision by your human partner, not a side effect of this skill.

## When a Delta Is Appropriate

A delta is appropriate when this change alters requirement-level behavior of at least one capability: introducing a new capability, or adding, modifying, or removing user-visible behavior of an existing one.

Skip with a one-line note for:
- Pure refactors (no visible behavior change)
- Tooling-only or docs-only changes

When genuinely unsure, ask your human partner before authoring anything.

## Inventory

Read `docs/specs/**/spec.md`. The capability id for each file is the directory path relative to `docs/specs/` — e.g. `docs/specs/user-auth/spec.md` → capability `user-auth`.

Two-pass read: skim the tree (headings and Purpose lines) to understand the landscape, then read only the capabilities this change plausibly touches.

## Author the Deltas

The `change-id` is the design doc filename stem: `docs/superpowers/specs/2026-10-03-topic-design.md` → `2026-10-03-topic`. Use what your human partner states when they name a different id.

Write one file per capability under `docs/specs/changes/<change-id>/specs/<capability-path>/spec.md`. Filename must be exactly `spec.md`. The name `changes` is reserved; a main spec must never live at `docs/specs/changes/spec.md`. Do not invent capability paths — every path must be an exact existing capability (for modifications) or a deliberate new one (for additions).

MODIFIED blocks are copied from the current main spec *whole* before editing. A new capability requires `## Purpose` (≥50 chars) plus ADDED requirements only.

## Delta Grammar

Each delta file opens with `# Spec Delta` and uses only these four operation sections:

```markdown
# Spec Delta

## Purpose
<!-- New capabilities ONLY: 50+ chars; seeds the new main spec's Purpose -->

## ADDED Requirements
### Requirement: <name>
<text with SHALL or MUST — one sentence, ≤500 chars>

#### Scenario: <name>
- **WHEN** <condition>
- **THEN** <expected outcome>

## MODIFIED Requirements
### Requirement: <existing name — byte-exact>
<COMPLETE replacement block: current block copied whole, then edited>

## REMOVED Requirements
### Requirement: <name>
**Reason**: <why it is being removed>
**Migration**: <what existing behavior/dependents do instead>

## RENAMED Requirements
- FROM: `### Requirement: <Old Name>`
- TO: `### Requirement: <New Name>`
```

Rules:

1. Every `### Requirement:` sits under one of the four operation sections. A requirement outside all four is an error.
2. Scenarios use exactly four hashtags (`#### Scenario:`). Three hashtags fail silently. Nothing inside a requirement block uses a heading — notes are list items or bold text only.
3. Every ADDED/MODIFIED requirement has ≥1 scenario. REMOVED needs only Reason + Migration. RENAMED uses FROM/TO pairs.
4. The same requirement name may not appear in two sections.
5. Requirement text carries SHALL or MUST and stays ≤500 chars. MODIFIED blocks may not be trimmed to satisfy the limit.
6. MODIFIED carries the **complete** replacement block — anything absent from the delta is lost at merge.
7. `## Purpose` appears only for a capability with no existing main spec.
8. When RENAMED entries exist, MODIFIED refers to the new name.
9. `#` lines inside fenced code blocks are content, never structure.
10. Capability paths must match an exact existing capability (MODIFIED/REMOVED/RENAMED) or name a deliberate new one (ADDED).

## Self-Validate

Run the ten rules above as a checklist against every delta file before handing off. Fix findings inline.

Spot-checks:
- Every `#### Scenario:` uses exactly four `#` characters
- No `### Requirement:` sits outside one of the four operation sections
- MODIFIED blocks are complete, not summarized
- No requirement name appears in more than one section
- `## Purpose` is present only for new capabilities with no existing main spec

## Hand Off

Report the delta paths to your human partner. These files join the design doc in brainstorming's spec self-review and user review gate, and are committed together with the design doc.

If no delta was appropriate, state which condition applied.
