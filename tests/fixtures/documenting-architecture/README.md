# Verifying the documenting-architecture skill against fixtures

These skills are markdown instructions, so verification is fixture-driven: set up a
fixture's inputs, follow the skill, and diff the result against the golden `expected/`.

## documenting-architecture — reconcile (finishing-flow path)

1. Copy the inputs into a scratch workspace:
   ```bash
   BASE=superpowers/tests/fixtures/documenting-architecture/reconcile-finishing
   rm -rf /tmp/da && mkdir -p /tmp/da
   cp "$BASE/before/architecture.md" /tmp/da/architecture.md
   ```
2. Follow the `documenting-architecture` skill's reconcile mode (finishing-flow path) rooted
   at `/tmp/da`, using `$BASE/change/design-doc.md` as the design-doc context and a dummy
   commit hash `def5678` for the marker.
3. Diff the result against the golden file, excluding the marker line (MUST be empty):
   ```bash
   diff -u <(grep -v 'last-reconciled' "$BASE/expected/architecture.md") \
           <(grep -v 'last-reconciled' /tmp/da/architecture.md)
   ```
4. Marker check: the marker line was updated to the new commit:
   ```bash
   grep -q '<!-- last-reconciled: def5678 -->' /tmp/da/architecture.md && echo "marker OK"
   ```
5. Idempotency: re-run reconcile against the same inputs and diff again — still empty, no
   duplicate entries:
   ```bash
   diff -u <(grep -v 'last-reconciled' "$BASE/expected/architecture.md") \
           <(grep -v 'last-reconciled' /tmp/da/architecture.md)
   ```

## documenting-architecture — on-demand reconcile

1. Set up the scratch git repo:
   ```bash
   bash superpowers/tests/fixtures/documenting-architecture/on-demand-reconcile/setup.sh /tmp/da-ondemand
   ```
2. Follow the `documenting-architecture` skill's reconcile mode (on-demand path) rooted at
   `/tmp/da-ondemand`, with no design doc (the agent scans `git log` since the marker).
3. Structural checks (the Done-entry ref is a dynamic commit hash, so check structure not
   exact text):
   ```bash
   DOC=/tmp/da-ondemand/docs/architecture.md
   grep -q '### Component: Worker' "$DOC" && echo "worker component added OK"
   grep -q 'Background task' "$DOC" && echo "new interaction OK"
   # The "Background worker" entry moved from Planned to Done
   done_section=$(sed -n '/^### Done$/,/^###/p' "$DOC")
   echo "$done_section" | grep -q 'Background worker' && echo "moved to Done OK"
   planned_section=$(sed -n '/^### Planned$/,$p' "$DOC")
   ! echo "$planned_section" | grep -q 'Background worker' && echo "removed from Planned OK"
   ```
4. Marker check: the marker was updated to HEAD:
   ```bash
   HEAD=$(git -C /tmp/da-ondemand rev-parse HEAD)
   grep -q "last-reconciled: $HEAD" "$DOC" && echo "marker OK"
   ```
5. Idempotency: re-run on-demand reconcile — the marker is already at HEAD, so it is a no-op:
   ```bash
   cp "$DOC" /tmp/da-ondemand-before
   # re-run reconcile (agent follows skill)
   diff -u /tmp/da-ondemand-before "$DOC" && echo "idempotent OK"
   ```
   MUST be empty — no duplicate entries, no changes on re-run.

## documenting-architecture — initialize

1. Copy the sample repo into a scratch workspace and init git:
   ```bash
   rm -rf /tmp/da-init && mkdir -p /tmp/da-init
   cp -r superpowers/tests/fixtures/documenting-architecture/initialize/sample-repo/* /tmp/da-init/
   cd /tmp/da-init && git init -q && git config user.email t@t && git config user.name t
   git add -A && git commit -qm "seed"
   ```
2. Follow the `documenting-architecture` skill's initialize mode rooted at `/tmp/da-init`
   (no `docs/architecture.md` exists yet).
3. Structural checks (the exact Overview prose is agent-written, so check structure not text):
   ```bash
   DOC=/tmp/da-init/docs/architecture.md
   grep -q '^<!-- last-reconciled:' "$DOC" && echo "marker OK"
   grep -q '^## Overview'      "$DOC" && echo "overview OK"
   grep -q '^## Component map' "$DOC" && echo "components OK"
   grep -q '^### Component:'   "$DOC" && echo "at least one component OK"
   grep -q '^## Key interactions'   "$DOC" && echo "interactions OK"
   grep -q '^## Tech stack'    "$DOC" && echo "tech stack OK"
   grep -q '^## Roadmap'       "$DOC" && echo "roadmap OK"
   grep -q '<TODO: verify>'    "$DOC" && echo "uncertain sections marked OK"
   ```

## documenting-architecture — staleness check

1. Set up the scratch git repo:
   ```bash
   bash superpowers/tests/fixtures/documenting-architecture/staleness/setup.sh /tmp/da-stale
   ```
2. Follow the `documenting-architecture` skill's consult mode (Mode 1) rooted at
   `/tmp/da-stale`. The agent MUST:
   - Read `docs/architecture.md`.
   - Run the staleness check (marker vs HEAD).
   - Surface "3 commits stale" to the user and suggest running on-demand reconcile before
     continuing.
3. Verify the staleness message mentions the commit count:
   ```bash
   # The agent's output should contain a staleness message. This is a manual check —
   # confirm the agent surfaced the message and offered to run reconcile.
   ```
   The fixture is satisfied when the agent surfaces the staleness and offers reconcile,
   regardless of whether the user accepts or declines (both paths are valid per the spec).
