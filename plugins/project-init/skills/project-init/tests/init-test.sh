#!/usr/bin/env bash
#
# Test suite for the project-init deterministic generator (scripts/scaffold.mjs).
#
# Runs the generator against tests/fixtures/example.spec.json in a sandbox and
# asserts: the emitted file set, the CANON 4-principle block byte-match, the core
# line ceiling + allowed-header allow-list, mission/routing content, agent
# frontmatter + `model: opus`, self-containment (no global path), determinism
# (two runs byte-identical), and the confidentiality scrub over the whole tree.
#
# Run it after ANY edit to scaffold.mjs or the templates:
#     bash tests/init-test.sh
# Exits non-zero if a single assertion fails.
#
set -u

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$TESTS_DIR/.." && pwd)"
PLUGIN_ROOT="$(cd "$SKILL_DIR/../.." && pwd)"
SCAFFOLD="$SKILL_DIR/scripts/scaffold.mjs"
FIXTURE="$TESTS_DIR/fixtures/example.spec.json"
CORE_TPL="$SKILL_DIR/references/core.template.md"

LINE_CEILING=70   # generated CLAUDE.md must stay a bounded, always-loaded core

SANDBOX="$(mktemp -d)"
PROJ="$SANDBOX/proj"
CLAUDE="$PROJ/CLAUDE.md"
AGENTS="$PROJ/.claude/agents"

PASS=0; FAIL=0
pass() { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
fail() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }
cleanup() { rm -rf "$SANDBOX"; }
trap cleanup EXIT

AGENT_COUNT="$(node -e 'process.stdout.write(String(JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).agents.length))' "$FIXTURE")"

echo "=== A. Generator runs and emits the expected file set ==="
if node "$SCAFFOLD" "$FIXTURE" "$PROJ" >"$SANDBOX/run.out" 2>"$SANDBOX/run.err"; then
  pass "scaffold exits 0"
else
  fail "scaffold exits 0 (see below)"; sed 's/^/    /' "$SANDBOX/run.err"
fi
[ -f "$CLAUDE" ]                        && pass "CLAUDE.md emitted"            || fail "CLAUDE.md emitted"
[ -f "$AGENTS/advisor.md" ]             && pass ".claude/agents/advisor.md"   || fail ".claude/agents/advisor.md"
[ -f "$PROJ/.claude/skill-feedback.md" ] && pass ".claude/skill-feedback.md"  || fail ".claude/skill-feedback.md"
[ -f "$PROJ/.claude/project-init.spec.json" ] && pass ".claude/project-init.spec.json" || fail ".claude/project-init.spec.json"

AGENT_FILES="$(ls "$AGENTS"/*.md 2>/dev/null | wc -l | tr -d ' ')"
if [ "$AGENT_FILES" -eq "$((AGENT_COUNT + 1))" ]; then
  pass "agent file count = $AGENT_COUNT seed + 1 advisor ($AGENT_FILES)"
else
  fail "agent file count: expected $((AGENT_COUNT + 1)) got $AGENT_FILES"
fi

echo
echo "=== B. CANON 4-principle block is byte-for-byte the canon ==="
awk 'index($0,"<!-- CANON:"){f=1} f{print} index($0,"<!-- /CANON -->"){f=0}' "$CORE_TPL"  > "$SANDBOX/canon_tpl.txt"
awk 'index($0,"<!-- CANON:"){f=1} f{print} index($0,"<!-- /CANON -->"){f=0}' "$CLAUDE"    > "$SANDBOX/canon_gen.txt"
if [ -s "$SANDBOX/canon_tpl.txt" ] && diff -q "$SANDBOX/canon_tpl.txt" "$SANDBOX/canon_gen.txt" >/dev/null; then
  pass "CANON block matches core.template.md byte-for-byte ($(wc -l < "$SANDBOX/canon_tpl.txt" | tr -d ' ') lines)"
else
  fail "CANON block differs from canon"; diff "$SANDBOX/canon_tpl.txt" "$SANDBOX/canon_gen.txt" | sed 's/^/    /'
fi

echo
echo "=== C. Core is bounded + only allowed section headers ==="
LINES="$(wc -l < "$CLAUDE" | tr -d ' ')"
if [ "$LINES" -le "$LINE_CEILING" ]; then pass "CLAUDE.md ${LINES} lines (<= ${LINE_CEILING})"
else fail "CLAUDE.md ${LINES} lines exceeds ceiling ${LINE_CEILING}"; fi

BAD_HEADER=0
while IFS= read -r line; do
  case "$line" in
    "# 프로젝트 운영 계약"|"## 미션"|"## 응답 방식"|"## 기본 원칙"|"## 운영 규율"|"## 라우팅"|"## 게이트") : ;;
    *) printf '    unexpected header: %s\n' "$line"; BAD_HEADER=1 ;;
  esac
done < <(grep '^#' "$CLAUDE")
[ "$BAD_HEADER" -eq 0 ] && pass "only allow-listed section headers present" || fail "disallowed header in CLAUDE.md"

echo
echo "=== D. Mission text + one routing line per agent ==="
MISSION="$(node -e 'process.stdout.write(JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).mission)' "$FIXTURE")"
grep -qF "$MISSION" "$CLAUDE" && pass "mission text present in core" || fail "mission text missing"
ROUTES="$(grep -c '「' "$CLAUDE" | tr -d ' ')"
if [ "$ROUTES" -eq "$AGENT_COUNT" ]; then pass "routing lines = agents ($ROUTES)"
else fail "routing lines: expected $AGENT_COUNT got $ROUTES"; fi

echo
echo "=== E. Every agent .md: valid frontmatter (name+description) + model: opus ==="
BAD_FM=0
for f in "$AGENTS"/*.md; do
  if grep -q '^name:' "$f" && grep -q '^description:' "$f" && grep -q '^model: opus' "$f"; then :
  else printf '    bad frontmatter: %s\n' "$(basename "$f")"; BAD_FM=1; fi
done
[ "$BAD_FM" -eq 0 ] && pass "all agent files have name+description+model: opus" || fail "an agent file has bad frontmatter"

echo
echo "=== F. Self-contained: no global path in generated output ==="
if grep -rIF -e '~/.claude' -e '/Users/' "$PROJ" >/dev/null 2>&1; then
  fail "generated output references a global path"; grep -rIF -n -e '~/.claude' -e '/Users/' "$PROJ" | sed 's/^/    /'
else
  pass "no ~/.claude or /Users/ reference in generated tree"
fi

echo
echo "=== G. Deterministic: two fresh runs are byte-identical ==="
D1="$SANDBOX/det1"; D2="$SANDBOX/det2"
node "$SCAFFOLD" "$FIXTURE" "$D1" >/dev/null 2>&1
node "$SCAFFOLD" "$FIXTURE" "$D2" >/dev/null 2>&1
if diff -r "$D1" "$D2" >/dev/null 2>&1; then pass "diff -r of two runs is empty"
else fail "two runs differ"; diff -r "$D1" "$D2" | sed 's/^/    /'; fi

echo
echo "=== H. Idempotent-safe: refuses overwrite without --force ==="
if node "$SCAFFOLD" "$FIXTURE" "$PROJ" >/dev/null 2>&1; then
  fail "re-run without --force should have refused"
else
  pass "re-run without --force refuses (exit non-zero)"
fi
if node "$SCAFFOLD" "$FIXTURE" "$PROJ" --force >/dev/null 2>&1; then
  pass "re-run with --force succeeds"
else
  fail "re-run with --force should succeed"
fi

echo
echo "=== I. Confidentiality scrub over the whole plugin tree ==="
# The test file itself names the banned tokens to check for them — exclude it.
BANNED=(RTK rtk graphify MIDAS MIDASIN "AX기반개발" InAX XRS GASA 신신역검 GASAOA OneDrive "ttlhi10@gmail.com" hsw0312 "THE MAX")
SCRUB_BAD=0
for tok in "${BANNED[@]}"; do
  if grep -rF --exclude=init-test.sh -e "$tok" "$PLUGIN_ROOT" >/dev/null 2>&1; then
    printf '    banned token present: %s\n' "$tok"
    grep -rF --exclude=init-test.sh -l -e "$tok" "$PLUGIN_ROOT" | sed 's/^/      in /'
    SCRUB_BAD=1
  fi
done
[ "$SCRUB_BAD" -eq 0 ] && pass "no banned token in plugin tree (sungwooHa/skills-marketplace allowed)" || fail "banned token(s) present"

echo
echo "================ PASS=$PASS  FAIL=$FAIL ================"
[ "$FAIL" -eq 0 ]
