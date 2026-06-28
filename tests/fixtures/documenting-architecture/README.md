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

## documenting-architecture — on-demand reconcile (Task 2 fixture)

See Task 2 for the on-demand fixture setup (requires a git repo with commits).

## documenting-architecture — initialize (Task 2 fixture)

See Task 2 for the initialize fixture setup.

## documenting-architecture — staleness check (Task 2 fixture)

See Task 2 for the staleness-check fixture setup.
