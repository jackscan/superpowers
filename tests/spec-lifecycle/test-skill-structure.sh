#!/usr/bin/env bash
# Structural checks for the spec-lifecycle skills (writing-spec-deltas,
# syncing-specs) and their integration points. Merge behavior is prose and
# is exercised in a throwaway scratch project at implementation time; this
# script checks what a shell can check: frontmatter, word budget, grammar
# anchors, and — the fork's real guard — that the pointer blocks sit in the
# three edited skills and README exactly where the design spec puts them,
# so an upstream merge that clobbers or moves one fails loudly.
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORD_BUDGET=1500

PASSES=0
FAILURES=0

pass() { echo "  [PASS] $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  [FAIL] $1"; FAILURES=$((FAILURES + 1)); }

frontmatter_name() {
  awk 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} NR>1{print}' "$1" \
    | grep -q "^name: $2$"
}

frontmatter_description() {
  awk 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} NR>1{print}' "$1" \
    | awk '/^description:/{sub(/^description:[ ]*/,""); print; found=1; next} found && /^[ ]/{print} found && !/^[ ]/{exit}' \
    | tr '\n' ' '
}

body_words() {
  awk 'BEGIN{fm=0} NR==1 && $0=="---"{fm=1; next} fm==1 && $0=="---"{fm=2; next} fm==2{print}' "$1" | wc -w | tr -d ' '
}

# check_skill SKILL_NAME — pass/fail the house frontmatter + budget checks.
check_skill() {
  skill="$1"
  md="$REPO_ROOT/skills/$skill/SKILL.md"
  if [ -f "$md" ]; then
    pass "skills/$skill/SKILL.md exists"
  else
    fail "skills/$skill/SKILL.md exists"
    return 1
  fi
  if frontmatter_name "$md" "$skill"; then
    pass "$skill: frontmatter name is $skill"
  else
    fail "$skill: frontmatter name is $skill"
  fi
  desc="$(frontmatter_description "$md")"
  if printf '%s' "$desc" | grep -q '^Use when'; then
    pass "$skill: description starts with 'Use when'"
  else
    fail "$skill: description starts with 'Use when' (got: ${desc:0:60})"
  fi
  if printf '%s' "$desc" | grep -q 'docs/specs'; then
    pass "$skill: description names docs/specs (trigger gate)"
  else
    fail "$skill: description names docs/specs (trigger gate)"
  fi
  if [ "${#desc}" -le 1024 ]; then
    pass "$skill: description under 1024 characters"
  else
    fail "$skill: description under 1024 characters (${#desc})"
  fi
  if grep -q '^allowed-tools:' "$md"; then
    fail "$skill: no allowed-tools frontmatter (house style)"
  else
    pass "$skill: no allowed-tools frontmatter (house style)"
  fi
  words="$(body_words "$md")"
  if [ "$words" -le "$WORD_BUDGET" ]; then
    pass "$skill: SKILL.md body within $WORD_BUDGET words ($words)"
  else
    fail "$skill: SKILL.md body within $WORD_BUDGET words ($words)"
  fi
  return 0
}

# contains FILE NEEDLE LABEL
contains() {
  if grep -q -- "$2" "$1"; then
    pass "$3"
  else
    fail "$3"
  fi
}

# contains_literal FILE NEEDLE LABEL — NEEDLE is matched as a fixed string
contains_literal() {
  if grep -qF -e "$2" "$1"; then
    pass "$3"
  else
    fail "$3"
  fi
}

echo "spec-lifecycle structure"

# --- writing-spec-deltas ---------------------------------------------------
if check_skill writing-spec-deltas; then
  WSD="$REPO_ROOT/skills/writing-spec-deltas/SKILL.md"
  for anchor in "## Project Check" "## When a Delta Is Appropriate" "## Inventory" "## Author the Deltas" "## Delta Grammar" "## Self-Validate" "## Hand Off" \
    "## ADDED Requirements" "## MODIFIED Requirements" "## REMOVED Requirements" "## RENAMED Requirements" \
    "#### Scenario:" "### Requirement:" "docs/specs/changes/" "Never create" "reserved" "## Purpose"; do
    contains "$WSD" "$anchor" "writing-spec-deltas carries anchor: $anchor"
  done
fi

# --- syncing-specs -----------------------------------------------------------
if check_skill syncing-specs; then
  SS="$REPO_ROOT/skills/syncing-specs/SKILL.md"
  for anchor in "## Project Check" "## Resolve the Change" "## Reconcile" "## Validate" \
    "## Merge (RENAMED → REMOVED → MODIFIED → ADDED)" "## New Capability" "## Retirement" \
    "## Verify" "## Archive" "## Report and Commit" \
    "## ADDED Requirements" "## MODIFIED Requirements" "## REMOVED Requirements" "## RENAMED Requirements" \
    "#### Scenario:" "### Requirement:" "docs/specs/changes/archive/" \
    "Reason" "Migration" "FROM:" "TO:" "scenario-loss" "Never create" "reserved"; do
    contains "$SS" "$anchor" "syncing-specs carries anchor: $anchor"
  done
fi

# --- pointer blocks in the three edited skills + README ----------------------
BS="$REPO_ROOT/skills/brainstorming/SKILL.md"
SDD="$REPO_ROOT/skills/subagent-driven-development/SKILL.md"
EP="$REPO_ROOT/skills/executing-plans/SKILL.md"

contains "$BS" "superpowers:writing-spec-deltas" "brainstorming points at superpowers:writing-spec-deltas"
contains "$SDD" "superpowers:syncing-specs" "subagent-driven-development points at superpowers:syncing-specs"
contains "$EP" "superpowers:syncing-specs" "executing-plans points at superpowers:syncing-specs"

# brainstorming: pointer must sit before the HARD-GATE
bs_anchor="$(grep -n 'superpowers:writing-spec-deltas' "$BS" | head -1 | cut -d: -f1)"
bs_gate="$(grep -n '<HARD-GATE>' "$BS" | head -1 | cut -d: -f1)"
if [ -n "$bs_anchor" ] && [ -n "$bs_gate" ] && [ "$bs_anchor" -lt "$bs_gate" ]; then
  pass "brainstorming pointer sits before the HARD-GATE"
else
  fail "brainstorming pointer sits before the HARD-GATE (anchor=$bs_anchor gate=$bs_gate)"
fi

pointer_between() {
  md="$1"
  skill="$2"
  a="$(grep -n 'superpowers:syncing-specs' "$md" | head -1 | cut -d: -f1)"
  f="$(grep -n '^## Final Review$' "$md" | head -1 | cut -d: -f1)"
  n="$(grep -n '^## Finish$' "$md" | head -1 | cut -d: -f1)"
  if [ -n "$a" ] && [ -n "$f" ] && [ -n "$n" ] && [ "$a" -gt "$f" ] && [ "$a" -lt "$n" ]; then
    pass "$skill pointer sits between Final Review and Finish"
  else
    fail "$skill pointer sits between Final Review and Finish (anchor=$a final=$f finish=$n)"
  fi
}
pointer_between "$SDD" "subagent-driven-development"
pointer_between "$EP" "executing-plans"

README="$REPO_ROOT/README.md"
contains_literal "$README" '**writing-spec-deltas** - OpenSpec-style delta specs at design time' "README lists writing-spec-deltas"
contains_literal "$README" '**syncing-specs** - Merge delta specs into canonical specs' "README lists syncing-specs"

# --- house voice + leak checks ---------------------------------------------
for skill in writing-spec-deltas syncing-specs; do
  md="$REPO_ROOT/skills/$skill/SKILL.md"
  if [ -f "$md" ]; then
    if grep -qi 'the user' "$md"; then
      fail "$skill: says 'the user' instead of 'your human partner'"
    else
      pass "$skill: says 'your human partner', not 'the user'"
    fi
    if grep -rn -E '/Users/|/home/' "$REPO_ROOT/skills/$skill" --include='*.md' 2>/dev/null; then
      fail "$skill: machine-specific paths in shipped files"
    else
      pass "$skill: no machine-specific paths in shipped files"
    fi
  fi
done

echo
echo "Passed: $PASSES  Failed: $FAILURES"
[ "$FAILURES" -eq 0 ]
