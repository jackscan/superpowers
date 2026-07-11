---
name: writing-spec-deltas
description: Use during brainstorming when a project keeps living specs under docs/specs/ — consult the existing canonical specs for context, and capture a behavior-only delta spec for the current change. Ported from OpenSpec conventions.
---

# Writing Spec Deltas

Maintain living, capability-scoped specifications alongside the superpowers workflow. This
skill has two jobs, used at two moments inside brainstorming. It is **opt-in**: only act
when `docs/specs/` exists, or when the user explicitly asks to start living specs.

**Announce at start:** "I'm using the writing-spec-deltas skill to <consult existing specs | capture the spec delta>."

## Job 1 — Consult (during "Explore project context")

Before proposing a design, ground yourself in the documented current behavior:

1. If `docs/specs/` does not exist and the user has not asked for living specs, skip this
   skill entirely.
2. Identify which capabilities the change will touch (by name, e.g. `auth`, `greeting`).
3. Read the matching `docs/specs/<capability>/spec.md` files. Treat their requirements and
   scenarios as the authoritative description of current behavior, and reconcile your
   design against them (what is new, what changes, what is removed).

## Job 2 — Capture (after the design doc is written and self-reviewed)

Write a **behavior-only** delta describing how this change alters the capabilities:

1. Determine the feature name `<feature>` = the kebab-case brainstorming topic (or a name
   agreed with the user). If `docs/specs/changes/<feature>/` already exists for this change, reuse it.
2. For each affected capability, create/append
   `docs/specs/changes/<feature>/specs/<capability>/spec.md`. Reuse an existing capability
   name when one fits; coin a new kebab-case name otherwise. Create `docs/specs/` and the
   change folders if they do not exist.
3. Write the delta using these operation sections (include only those that apply):

   ```markdown
   ## ADDED Requirements
   ### Requirement: <Name>
   The system SHALL <observable behavior>.

   #### Scenario: <name>
   - **WHEN** <trigger>
   - **THEN** <observable outcome>
   - **AND** <additional outcome, optional>

   ## MODIFIED Requirements
   ### Requirement: <existing Name>
   #### Scenario: <only the scenario(s) being added or changed>
   - **WHEN** ...
   - **THEN** ...

   ## REMOVED Requirements
   ### Requirement: <Name>

   ## RENAMED Requirements
   - FROM: `### Requirement: <Old Name>`
   - TO: `### Requirement: <New Name>`
   ```

4. **Behavior-first.** Capture externally observable behavior, inputs/outputs, errors, and
   constraints. Keep implementation detail (libraries, class/function structure) out of the
   spec — that belongs in the design doc. This delta **supplements** the design doc; it does
   not replace it.
5. **Progressive rigor.** Keep it lightweight. A change with no observable behavior change
   needs no delta — say so and skip.

## Self-check before finishing

Re-read each delta you wrote and confirm:
- Every `### Requirement:` under ADDED/MODIFIED has at least one `#### Scenario:` (except
  REMOVED, which is a heading only, and RENAMED, which uses FROM/TO lines).
- Every scenario has at least a `**WHEN**` and a `**THEN**` bullet.
- Operation section headers are exactly `## ADDED Requirements`, `## MODIFIED Requirements`,
  `## REMOVED Requirements`, `## RENAMED Requirements`.

If a check fails, fix it. If you cannot (e.g. a requirement genuinely has no testable
scenario), stop and ask the user rather than writing an unverifiable spec.

## Commit

Commit the delta with the rest of the change:

```bash
git add docs/specs/changes/<feature>
git commit -m "spec: capture <feature> behavior delta"
```
