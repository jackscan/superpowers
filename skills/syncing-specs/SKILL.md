---
name: syncing-specs
description: Use at finishing time to merge a feature's delta specs under docs/specs/changes/<feature>/ into the canonical specs under docs/specs/, then archive the deltas. Agent-driven, idempotent. Ported from OpenSpec.
---

# Syncing Delta Specs into Canonical Specs

Merge a feature's delta specs into the canonical, living specs, then archive the deltas.

This is an **agent-driven** operation: you read the deltas and directly edit the canonical
specs, so you can merge intelligently (e.g. add one scenario without restating a whole
requirement). It MUST be idempotent — running it twice produces the same result.

**Announce at start:** "I'm using the syncing-specs skill to merge spec deltas into the canonical specs."

## Inputs

- **Feature name** `<feature>` — the name of the change directory under
  `docs/specs/changes/`. The deltas live under `docs/specs/changes/<feature>/specs/`.
- If a feature name is passed by the invoking skill (e.g. `finishing-work`), use it.
- If no feature name is given, discover it: list `docs/specs/changes/` (ignore `archive/`).
  Exactly one → use it. Multiple → present them and ask the user to choose. None → report
  "No delta specs to sync" and stop.
- Do not derive `<feature>` from the git branch — branching is not part of this workflow,
  so the branch is not a reliable feature identifier.

## Steps

1. **Locate the deltas.** List `docs/specs/changes/<feature>/specs/*/spec.md`. If none
   exist, report "No delta specs to sync" and stop.

2. **For each delta file** at `docs/specs/changes/<feature>/specs/<capability>/spec.md`:

   a. Read the delta. It contains any of: `## ADDED Requirements`,
      `## MODIFIED Requirements`, `## REMOVED Requirements`, `## RENAMED Requirements`.

   b. Read the canonical spec at `docs/specs/<capability>/spec.md` (it may not exist).

   c. Apply each operation to the canonical content:

      - **ADDED** — for each `### Requirement: <Name>`: if it is absent from canonical,
        append the full requirement block (heading, SHALL line, all scenarios) at the end
        of the `## Requirements` section (insert before the next top-level `## ` heading, or at end of file if none follows). If it is already present and identical, do
        nothing (idempotent). If present but different, update it to match the delta.
      - **MODIFIED** — for each `### Requirement: <Name>`: find it in canonical and apply
        the change. The delta lists only the scenarios (or description) being added or
        changed; **preserve existing scenarios not mentioned**. Append a new scenario at
        the end of that requirement's scenarios; if an identically-named scenario already
        exists, replace it. If the named requirement is absent from canonical, treat it as
        ADDED.
      - **REMOVED** — for each `### Requirement: <Name>`: delete that entire requirement
        block from canonical. If already absent, do nothing.
      - **RENAMED** — for each `- FROM:` / `- TO:` pair: change the heading from the FROM
        name to the TO name, preserving the requirement's body and position. If the FROM
        heading is absent (already renamed), do nothing.

   d. **New capability** — if the canonical spec did not exist, create
      `docs/specs/<capability>/spec.md` with this structure, writing a one- or two-line
      Purpose that summarizes the capability, then the `## Requirements` section containing
      the ADDED requirements:

      ```markdown
      # <capability> Specification

      ## Purpose
      <one or two lines describing the capability>

      ## Requirements
      <the ADDED requirement blocks>
      ```

   e. Write the updated canonical spec back to `docs/specs/<capability>/spec.md`.

3. **Archive the deltas.** Move the whole change folder to the dated archive:

   ```bash
   mkdir -p docs/specs/changes/archive
   git mv docs/specs/changes/<feature> docs/specs/changes/archive/$(date +%F)-<feature>
   ```
   (Use `mv` if the files are not tracked by git yet.) If the target already exists, stop
   and report the collision rather than overwriting.

4. **Report** what changed per capability: requirements added / modified / removed /
   renamed, and any new capability spec files created. If nothing changed (already in
   sync), say so.

## Guardrails

- Read both the delta and the canonical spec before editing.
- Preserve canonical content not mentioned in the delta.
- Idempotent: re-running yields the same result — treat "already applied" operations as
  no-ops, never duplicate.
- If a canonical spec has diverged in a way that makes an operation ambiguous, show the
  conflict and ask the user rather than guessing.
- Do not touch design docs under `docs/superpowers/`.
