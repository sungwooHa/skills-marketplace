#!/usr/bin/env bash
# ui-review plugin regression test
# Checks: manifest validity, skill layout, frontmatter contract, and the
# generality gate (no project-of-origin residue — promotion gate #1).
set -u
PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$PLUGIN_DIR/../.." && pwd)"
PASS=0; FAIL=0

ok()   { PASS=$((PASS+1)); echo "  ok: $1"; }
fail() { FAIL=$((FAIL+1)); echo "FAIL: $1"; }

check() { # check <desc> <cmd...>
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then ok "$desc"; else fail "$desc"; fi
}

echo "== manifest =="
check "plugin.json is valid JSON" python3 -c "import json;json.load(open('$PLUGIN_DIR/.claude-plugin/plugin.json'))"
check "plugin.json name is ui-review" python3 -c "
import json;assert json.load(open('$PLUGIN_DIR/.claude-plugin/plugin.json'))['name']=='ui-review'"
check "plugin.json has no legacy 'skills' field" python3 -c "
import json;assert 'skills' not in json.load(open('$PLUGIN_DIR/.claude-plugin/plugin.json'))"

echo "== layout =="
for s in design-review motion-review; do
  check "skills/$s/SKILL.md exists" test -f "$PLUGIN_DIR/skills/$s/SKILL.md"
  check "frontmatter name matches folder ($s)" grep -q "^name: $s$" "$PLUGIN_DIR/skills/$s/SKILL.md"
  check "description starts with 'Use when' ($s)" grep -q "^description: Use when" "$PLUGIN_DIR/skills/$s/SKILL.md"
  check "description routes away non-targets ($s)" grep -q "NOT for" "$PLUGIN_DIR/skills/$s/SKILL.md"
done
check "ui-copy-rules reference exists" test -f "$PLUGIN_DIR/skills/design-review/references/ui-copy-rules.md"
check "compose-rules reference exists" test -f "$PLUGIN_DIR/skills/motion-review/references/compose-rules.md"
check "local.md example exists" test -f "$PLUGIN_DIR/ui-review.local.md.example"

echo "== content contract =="
check "design-review covers checks A-M" grep -q "M. Terminology leakage" "$PLUGIN_DIR/skills/design-review/SKILL.md"
check "motion-review has 4-question gate" grep -q "4-question gate" "$PLUGIN_DIR/skills/motion-review/SKILL.md"
check "motion-review has rationalization table (R27)" grep -q "^| R27 " "$PLUGIN_DIR/skills/motion-review/SKILL.md"
check "motion-review mandates reduced-motion field" grep -q "reduced-motion" "$PLUGIN_DIR/skills/motion-review/SKILL.md"
check "compose-rules ledger has 101 rows" bash -c "
  [ \"\$(grep -c '^| [0-9]' '$PLUGIN_DIR/skills/motion-review/references/compose-rules.md')\" -eq 101 ]"

echo "== generality gate (no project-of-origin residue in skills/) =="
if grep -rniE "s20|aurora|attendance|/Users/" "$PLUGIN_DIR/skills" >/dev/null 2>&1; then
  fail "skills/ contains project-of-origin residue:"
  grep -rniE "s20|aurora|attendance|/Users/" "$PLUGIN_DIR/skills" | head -5
else
  ok "skills/ free of s20/aurora/attendance/absolute-path residue"
fi

echo "== marketplace registration =="
if [ -f "$REPO_ROOT/.claude-plugin/marketplace.json" ]; then
  check "registered in marketplace.json" python3 -c "
import json;m=json.load(open('$REPO_ROOT/.claude-plugin/marketplace.json'));assert any(p['name']=='ui-review' for p in m['plugins'])"
else
  echo "  skip: marketplace.json not reachable (standalone checkout)"
fi

echo
echo "passed $PASS, failed $FAIL"
[ "$FAIL" -eq 0 ]
