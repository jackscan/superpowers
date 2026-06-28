---
name: documenting-architecture
description: Use when a project keeps a living architecture doc at docs/architecture.md — consult it during brainstorming for current structure, add a roadmap entry after the design doc, and reconcile it at finishing or on-demand when changes land.
---

# Documenting Architecture

Maintain a living architecture & roadmap document at `docs/architecture.md`. An agent
consults it before making changes and reconciles it when changes land. Complements the
behavior specs under `docs/specs/` (which capture *what the system does*); this captures
*how the system is structured* (components, interactions) and *where the project stands*
(roadmap).

**Opt-in:** only act when `docs/architecture.md` exists, or when the user explicitly asks
to initialize one. Absent the file, Modes 1–3 no-op; Mode 4 creates it.

**Announce at start:** "I'm using the documenting-architecture skill to <consult | add a roadmap entry | reconcile | initialize>."

## Doc format

`docs/architecture.md` uses this structure:

```markdown
<!-- last-reconciled: <commit-hash> -->
# <Project> Architecture

## Overview
<1 paragraph: what the system is, its purpose, primary users>

## Component map
### Component: <name>
- **Responsibility:** <one line>
- **Depends on:** <other components / external services>
- **Key interfaces:** <entrypoints, APIs, files of note>
- **Location:** <top-level path(s) in the repo>

(repeat per component)

## Key interactions
<2-5 representative flows, each a short numbered list or a one-line ASCII/Mermaid diagram>

## Tech stack & constraints
- **Languages / frameworks:** ...
- **Key constraints:** <non-negotiable design constraints, external integrations>

## Roadmap
### Done
- <item> -- <design-doc or commit ref, date>

### In progress
- <item> -- <link to in-flight design doc / branch>

### Planned
- <item> -- <brief note, optional>
```

The `last-reconciled` marker at the top tracks freshness for the staleness check (Mode 1)
and the on-demand scan range (Mode 3).

## Mode 1 — Consult (during brainstorming's "Explore project context")

If `docs/architecture.md` exists, read it. Treat the component map as the authoritative
current structure; reconcile the design against it:
- Which components does this change touch?
- Does it introduce a new component?
- Does it change interactions between existing components?

**Staleness check.** Before trusting the doc, check the `last-reconciled` marker against
`HEAD`:

```bash
marker=$(grep -o 'last-reconciled: [a-f0-9]\+' docs/architecture.md | head -1 | cut -d' ' -f2)
if [ -n "$marker" ]; then
  count=$(git rev-list --count "${marker}..HEAD" 2>/dev/null || echo "unknown")
  if [ "$count" != "0" ] && [ "$count" != "unknown" ]; then
    echo "docs/architecture.md is $count commits stale (last reconciled at ${marker:0:8})."
  fi
fi
```

- If stale (N > 0): **surface this to the user and suggest running on-demand reconcile
  before continuing**, e.g.:

  > `docs/architecture.md` is N commits stale (last reconciled at <short-hash>). Run
  > `documenting-architecture` reconcile now to bring it current before designing this
  > change? (y/n)

  - If the user accepts, invoke reconcile (on-demand path, Mode 3) and re-read the updated
    doc before continuing the design.
  - If the user declines, proceed using the stale doc as-is, but verify structure against
    the actual code where it matters for the design.
- If the marker is missing: do not block — note that freshness is unknown and proceed.
  Optionally suggest a one-time on-demand reconcile to establish the marker.
- If the marker is at HEAD: the doc is current — proceed normally.

If `docs/architecture.md` does not exist, this mode no-ops (the user may invoke Mode 4 to
start).

## Mode 2 — Roadmap entry (after the design doc is written, at brainstorming)

Add an entry under `## Roadmap` -> `### In progress` linking to the design doc:

```markdown
- <feature> -- docs/superpowers/specs/<date>-<topic>-design.md
```

If the change is exploratory and may not be implemented yet, use `### Planned` instead. The
entry is the shared key that Mode 3 looks for at finishing time.

If `docs/architecture.md` does not exist, this mode no-ops.

## Mode 3 — Reconcile (at finishing, or on-demand)

Update `docs/architecture.md` to reflect what landed. Two invocation paths:

### Path A — At finishing (workflow-synced)

Invoked only when integrating via **Option 1 (merge locally)** or **Option 2 (push and
create a PR)** — skipped for Options 3 (keep as-is) and 4 (discard). The change has a
design doc that supplies context: edit the doc based on what the design doc + diff say
changed.

### Path B — On-demand (manual invoke)

The user (or the agent, at the user's request) invokes reconcile directly. This covers
commits made directly to the main branch and any other case where the doc has drifted.
Without a design doc, scan `git log` since the last reconcile marker:

```bash
marker=$(grep -o 'last-reconciled: [a-f0-9]\+' docs/architecture.md | head -1 | cut -d' ' -f2)
if [ -n "$marker" ]; then
  git log --oneline "${marker}..HEAD"
else
  git log --oneline -20
fi
```

If there is no marker, scan a bounded recent window (default: last 20 commits) and mark
uncertain updates with `<TODO: verify>`.

### Reconcile marker

Reconcile writes/updates the marker at the top of `docs/architecture.md`:

```markdown
<!-- last-reconciled: <commit-hash> -->
```

Use the post-merge commit (finishing path) or `HEAD` (on-demand path). If the marker is
already at or ahead of `HEAD`, on-demand reconcile is a no-op.

### What to update

For each affected area:
- **Components added / modified / removed** -> update the component map blocks. A component
  block is "modified" if its responsibility, dependencies, key interfaces, or location
  changed. Preserve component blocks not touched by this change.
- **New or changed interactions** -> update Key interactions. Add a new flow or revise an
  existing one; do not restate unchanged flows.
- **Tech stack & constraints** -> update if the change introduces a new language, framework,
  or external dependency, or changes a non-negotiable constraint. Otherwise leave unchanged.
- **Roadmap** -> move the matching `### In progress` (or `### Planned`) entry to `### Done`
  with a ref (the commit hash, or the design-doc path if no commit yet). If no prior entry
  exists, add a fresh Done line — do not fail. For the on-demand path, one Done line per
  landed change in the scanned range.
- **Idempotent:** re-running yields the same result. Treat "already applied" operations as
  no-ops, never duplicate entries.
- **Trivial changes** (tests, docs, pure refactor with no structural impact) may no-op the
  component map update — leave it untouched, optionally add a Done line or nothing.

### Guardrails

- Read the current `docs/architecture.md` before editing.
- Preserve content not touched by the change.
- If the doc has diverged in a way that makes an update ambiguous, show the conflict and
  ask the user rather than guessing.
- Do not touch design docs under `docs/superpowers/` or behavior specs under `docs/specs/`.
- For the on-demand path, mark uncertain inferences with `<TODO: verify>` rather than
  guessing.

## Mode 4 — Initialize (on-demand, explicit invocation)

If `docs/architecture.md` does not exist and the user wants to start, scan the repo and
write a first draft:

- Top-level directory layout
- README / package manifests (package.json, Cargo.toml, pyproject.toml, go.mod, etc.)
- Existing behavior specs under `docs/specs/` (if any) — each capability maps to a component
- Existing design docs under `docs/superpowers/specs/` — seed the roadmap Done/In-progress
  entries from them

Write the draft using the doc format above. Mark uncertain sections with `<TODO: verify>`.
Set the `last-reconciled` marker to `HEAD`. The user reviews and edits before it becomes
the living doc.

## Self-check before finishing (reconcile mode)

Re-read the updated `docs/architecture.md` and confirm:
- Every `### Component:` block has all four fields (Responsibility, Depends on, Key
  interfaces, Location), unless the component is new and marked `<TODO: verify>`.
- The `last-reconciled` marker is present and set to the correct commit.
- No duplicate roadmap entries (idempotency).
- Section headers are exactly: `## Overview`, `## Component map`, `## Key interactions`,
  `## Tech stack & constraints`, `## Roadmap` (with `### Done`, `### In progress`,
  `### Planned`).

If a check fails, fix it. If you cannot, stop and ask the user.
