#!/usr/bin/env bash
#
# Test suite for the deck-harness plugin.
#
# Two jobs, in priority order:
#   1. CONFIDENTIALITY — assert that no scrubbed term ever reappears. This repo is public and under a
#      personal GitHub account, while the source material came from company work. A term creeping back in
#      is the one failure mode that cannot be undone after a push.
#   2. STRUCTURAL INTEGRITY — frontmatter, referenced files exist, no machine-local paths.
#
# Run after ANY edit under plugins/deck-harness/:
#     bash plugins/deck-harness/tests/plugin-test.sh
# Exits non-zero if a single assertion fails.
#
# When you scrub a new term, add it to the SCRUBBED roster below in the same commit. A confidentiality
# gate that regresses silently is worse than no gate.
#
set -u
PLUGIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0; FAIL=0

check() { # check <description> <0-or-1 result>
  if [ "$2" -eq 0 ]; then PASS=$((PASS+1)); printf '  ok   %s\n' "$1"
  else FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; fi
}

# absent <label> <extended-regex> — passes when the pattern appears nowhere in the plugin
absent() {
  local hits
  hits=$(grep -rIloE "$2" "$PLUGIN" 2>/dev/null | grep -v '/tests/' || true)
  if [ -z "$hits" ]; then check "$1" 0
  else check "$1 — found in: $(echo "$hits" | tr '\n' ' ')" 1; fi
}

# exists <path-relative-to-plugin>
exists() { [ -e "$PLUGIN/$1" ] && check "exists: $1" 0 || check "exists: $1" 1; }

# fm_name <file> — echo the frontmatter `name:` value, unquoted
fm_name() {
  awk '/^---$/{n++; if(n==2) exit; next}
       n==1 && /^name:/{ sub(/^name:[[:space:]]*/,""); gsub(/^["'"'"']|["'"'"']$/,""); print; exit }' "$1"
}

# ---------------------------------------------------------------------------
# Scrubbed-term roster.
#
# The terms themselves are base64-encoded ON PURPOSE. This file ships in a PUBLIC repo, and a plaintext
# list of the company product names, internal codenames, and employee names we scrubbed would leak exactly
# what the scrub was meant to remove. Encoding keeps every assertion fully effective while the roster stays
# unreadable to a casual browser. Decode one with:  echo '<blob>' | base64 -d
#
# Each entry is "<label>|<base64 of an extended-regex>". Add a line here whenever you scrub a new term.
# ---------------------------------------------------------------------------
SCRUBBED=(
  "no company name|KF58W15hLXpBLVpdKVtNbV1bSWldW0RkXVtBYV1bU3NdKFteYS16QS1aXXwkKXzrr7jri6TsiqR866eI7J2064uk7Iqk"
  "no product name 1|KF58W15hLXpBLVpdKVtPb11bTm5dW1NzXVtJaV1bVHRdW0VlXShbXmEtekEtWl18JCl87Jio7IKs7J207Yq4"
  "no product name 2|KF58W15hLXpBLVpdKVtJaV1bTm5dW0FhXVtYeF0oW15hLXpBLVpdfCQp"
  "no product name 3|KF58W15hLXpBLVpdKVhSUyhbXmEtekEtWl18JCk="
  "no internal project codenames|KF58W15hLXpBLVpdKShHQVNBfEdBU0FPQXxPS0lUfENTSE18U0FHQSkoW15hLXpBLVpdfCQp"
  "no product name 4|W0hoXW9tZVtQcF1sYW587LyA7Ja07ZSM66Gc7Jqw"
  "no internal programme name|VEhFID9NQVh8VEhFTUFY"
  "no employee names|7ZWY7ISx7JqwfOuwleynhOyasHzquYDrr7jsl7A="
  "no personal deck name|7J6Q6riw7IaM6rCc"
  "no golden-deck name|6rGw7Jq4"
  "no deck-event provenance|7Jio67O065SpIOuwnO2RnA=="
  "no personal git host alias|Z2l0LXR0bGhpMTA="
  "no source-repo name|UHJlc2VudGF0aW9uLUhhcm5lc3M="
)

echo "=== A. Confidentiality: scrubbed proper nouns must not reappear ==="
for entry in "${SCRUBBED[@]}"; do
  absent "${entry%%|*}" "$(printf '%s' "${entry#*|}" | base64 -d)"
done

echo
echo "=== B. Confidentiality: trackers, wikis, internal hosts, build provenance ==="
absent "no Jira reference"                  '[Jj][Ii][Rr][Aa]'
absent "no Confluence reference"            '[Cc]onfluence|atlassian'
absent "no internal/private hostnames"      'https?://[a-zA-Z0-9.-]*\.(local|internal|corp|intra)'
absent "no dated feedback provenance tags"  '\(20[0-9][0-9]-[0-9][0-9]-[0-9][0-9], '
absent "no brand font name"                 '[Pp]aperlogy'

echo
echo "=== D. No machine-local or company folder paths ==="
absent "no /Users/ absolute paths"                '/Users/'
absent "no /home/ absolute paths"                 '/home/[a-z]'
absent "no OneDrive / CloudStorage paths"         'OneDrive|CloudStorage'
absent "no numbered company workspace folders"    '(00|01|02|03|99) (product|ops|lab|docs|know-how)'

echo
echo "=== E. Plugin manifest ==="
MANIFEST="$PLUGIN/.claude-plugin/plugin.json"
exists ".claude-plugin/plugin.json"
python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$MANIFEST" 2>/dev/null
check "plugin.json is valid JSON" $?
for field in name version description author homepage repository license keywords; do
  python3 -c "
import json,sys
d=json.load(open(sys.argv[1]))
sys.exit(0 if sys.argv[2] in d and d[sys.argv[2]] else 1)" "$MANIFEST" "$field" 2>/dev/null
  check "plugin.json has non-empty '$field'" $?
done
python3 -c "
import json,sys
d=json.load(open(sys.argv[1]))
sys.exit(0 if d.get('name')=='deck-harness' else 1)" "$MANIFEST" 2>/dev/null
check "plugin.json name == deck-harness" $?
python3 -c "
import json,sys
d=json.load(open(sys.argv[1]))
sys.exit(0 if d.get('version')=='1.0.0' else 1)" "$MANIFEST" 2>/dev/null
check "plugin.json version == 1.0.0" $?
python3 -c "
import json,sys
d=json.load(open(sys.argv[1]))
sys.exit(1 if 'skills' in d else 0)" "$MANIFEST" 2>/dev/null
check "plugin.json omits legacy 'skills' field (auto-discovery is standard)" $?

echo
echo "=== F. Skills: layout + frontmatter ==="
SKILL_COUNT=0
for d in "$PLUGIN"/skills/*/; do
  s=$(basename "$d"); SKILL_COUNT=$((SKILL_COUNT+1))
  f="$d/SKILL.md"
  [ -f "$f" ] && check "skills/$s/SKILL.md exists (capital SKILL.md)" 0 \
               || { check "skills/$s/SKILL.md exists (capital SKILL.md)" 1; continue; }
  head -1 "$f" | grep -qx -- '---'
  check "skills/$s: frontmatter opens on line 1" $?
  awk 'NR>1 && /^---$/{found=1; exit} END{exit !found}' "$f"
  check "skills/$s: frontmatter closes" $?
  awk '/^---$/{n++; next} n==1 && /^name:[[:space:]]*[^[:space:]]/{ok=1} END{exit !ok}' "$f"
  check "skills/$s: frontmatter has non-empty name" $?
  awk '/^---$/{n++; next} n==1 && /^description:[[:space:]]*[^[:space:]]/{ok=1} END{exit !ok}' "$f"
  check "skills/$s: frontmatter has non-empty description" $?
  [ "$(fm_name "$f")" = "$s" ]
  check "skills/$s: frontmatter name matches directory name" $?
done
[ "$SKILL_COUNT" -eq 2 ] && check "skill count == 2" 0 || check "skill count == 2 (got $SKILL_COUNT)" 1

echo
echo "=== G. Agents: layout + frontmatter ==="
AGENT_COUNT=0
for f in "$PLUGIN"/agents/*.md; do
  a=$(basename "$f" .md); AGENT_COUNT=$((AGENT_COUNT+1))
  head -1 "$f" | grep -qx -- '---'
  check "agents/$a: frontmatter opens on line 1" $?
  awk '/^---$/{n++; next} n==1 && /^name:[[:space:]]*[^[:space:]]/{ok=1} END{exit !ok}' "$f"
  check "agents/$a: frontmatter has non-empty name" $?
  awk '/^---$/{n++; next} n==1 && /^description:[[:space:]]*[^[:space:]]/{ok=1} END{exit !ok}' "$f"
  check "agents/$a: frontmatter has non-empty description" $?
  [ "$(fm_name "$f")" = "$a" ]
  check "agents/$a: frontmatter name matches filename" $?
done
[ "$AGENT_COUNT" -eq 9 ] && check "agent count == 9" 0 || check "agent count == 9 (got $AGENT_COUNT)" 1

echo
echo "=== H. Referenced assets actually exist ==="
GP="skills/generate-presentation"
exists "$GP/assets/templates/index.html"
exists "$GP/assets/templates/스크립트_화면.html"
exists "$GP/assets/templates/slide-patterns.html"
exists "$GP/assets/templates/CLAUDE.md"
exists "$GP/scripts/build_pptx_screenshot.py"
exists "$GP/scripts/requirements.txt"
exists "$GP/references/palette-presets.md"
exists "$GP/references/slide-layout-patterns.md"
exists "$GP/references/data-viz-guide.md"
exists "skills/feedback-consolidator/scripts/consolidate_feedback.py"
exists "README.md"
exists "deck-harness.local.md.example"

# Every ${CLAUDE_PLUGIN_ROOT}/... path mentioned in skills+agents must resolve to a real file.
MISSING=""
while read -r p; do
  [ -z "$p" ] && continue
  rel="${p#\$\{CLAUDE_PLUGIN_ROOT\}/}"
  [ -e "$PLUGIN/$rel" ] || MISSING="$MISSING $rel"
done < <(grep -rhoE '\$\{CLAUDE_PLUGIN_ROOT\}/[A-Za-z0-9._가-힣/-]+' "$PLUGIN/skills" "$PLUGIN/agents" 2>/dev/null \
         | sed 's/[.,)`]*$//' | sort -u)
[ -z "$MISSING" ] && check "all \${CLAUDE_PLUGIN_ROOT} paths resolve" 0 \
                  || check "all \${CLAUDE_PLUGIN_ROOT} paths resolve — missing:$MISSING" 1

echo
echo "=== I. Dead references to dropped skills ==="
absent "no reference to dropped skill data-visualization-guide" 'data-visualization-guide'
absent "no reference to dropped skill slide-layout-patterns as a skill" '`slide-layout-patterns` (스킬|skill)'
absent "no reference to dropped presentation-orchestrator lineage" 'presentation-orchestrator|narrative-architect|audience-strategist|slide-composer|visual-director|design-reviewer'
absent "no reference to non-existent info-architect agent" 'info-architect'
absent "no reference to non-existent visual-designer agent" 'visual-designer'

echo
echo "=== J. Templates are de-branded and placeholder-driven ==="
grep -q "DeckSans" "$PLUGIN/$GP/assets/templates/index.html"
check "index.html declares the neutral DeckSans family" $?
grep -q -- "-apple-system, sans-serif" "$PLUGIN/$GP/assets/templates/index.html"
check "index.html keeps a system-sans fallback (renders with no font installed)" $?
grep -q "{{DECK_TITLE}}" "$PLUGIN/$GP/assets/templates/index.html"
check "index.html is placeholder-driven ({{DECK_TITLE}})" $?
grep -q "{{MOTIF_GLYPH}}" "$PLUGIN/$GP/assets/templates/index.html"
check "transition overlay glyph is a placeholder, not personal content" $?
! grep -rq "font-family: 'Paperlogy'" "$PLUGIN/$GP/assets/templates/"
check "no branded font family remains in templates" $?

echo
echo "=== K. Python scripts are syntactically valid ==="
for f in "$PLUGIN/$GP/scripts/build_pptx_screenshot.py" \
         "$PLUGIN/skills/feedback-consolidator/scripts/consolidate_feedback.py"; do
  python3 -m py_compile "$f" 2>/dev/null
  check "py_compile: $(basename "$f")" $?
done
rm -rf "$PLUGIN"/**/__pycache__ "$PLUGIN"/skills/*/scripts/__pycache__ 2>/dev/null

echo
echo "=== L. No stray build artifacts or local-only material ==="
absent "no __pycache__ committed"                 '__pycache__'
[ ! -d "$PLUGIN/feedback" ] && check "no feedback/ dir (local-only capture must not ship)" 0 \
                            || check "no feedback/ dir (local-only capture must not ship)" 1
[ ! -d "$PLUGIN/output" ]   && check "no output/ dir (real decks must not ship)" 0 \
                            || check "no output/ dir (real decks must not ship)" 1
[ ! -d "$PLUGIN/_workspace" ] && check "no _workspace/ dir (real plan.md must not ship)" 0 \
                              || check "no _workspace/ dir (real plan.md must not ship)" 1
[ -z "$(find "$PLUGIN" -name '*.otf' -o -name '*.ttf' 2>/dev/null)" ] \
  && check "no font binaries shipped (licence surface stays zero)" 0 \
  || check "no font binaries shipped (licence surface stays zero)" 1
[ -z "$(find "$PLUGIN" -name '.DS_Store' 2>/dev/null)" ] \
  && check "no .DS_Store" 0 || check "no .DS_Store" 1

echo
echo "=== M. Palette catalog: structural invariants ==="
# The hex values themselves are the author's own, field-proven work and may legitimately churn, so nothing
# here hardcodes a color. What is asserted is the structure that actually makes the catalog usable: three
# presets, well-formed tables, exactly one accent per preset, and verdict colors that never collide with the
# accent/category colors (the role separation the catalog exists to teach).
PAL_PY="$(mktemp)"
cat >"$PAL_PY" <<'PY'
import re, sys

src = open(sys.argv[1], encoding='utf-8').read()
out = []
def chk(ok, label): out.append(("OK" if ok else "NO") + "|" + label)

secs = {}
for m in re.finditer(r'^## ([A-Z])\. ', src, re.M):
    start = m.end()
    nxt = re.search(r'^## ', src[start:], re.M)
    secs[m.group(1)] = src[start:start + (nxt.start() if nxt else len(src))]

chk(sorted(secs) == ['A', 'B', 'C'], "catalog defines exactly 3 presets (A/B/C)")

HEX = re.compile(r'#[0-9A-Fa-f]{3}(?:[0-9A-Fa-f]{3})?(?![0-9A-Fa-f])')
bad = [t for t in re.findall(r'`(#[^`]*)`', src)
       if not re.fullmatch(r'#(?:[0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})', t)]
chk(not bad, "every quoted color literal is a well-formed hex" + (" — bad: %s" % bad if bad else ""))

def cells(row): return [c.strip() for c in row.strip().strip('|').split('|')]

for k in sorted(secs):
    rows = [r for r in secs[k].splitlines() if r.strip().startswith('|')]
    ok_tbl = len(rows) >= 3 and set(rows[1].replace('|', '').strip()) <= set('-: ')
    chk(ok_tbl, "preset %s: token table is well-formed (header + separator + rows)" % k)
    if not ok_tbl:
        continue
    body = rows[2:]
    chk(all(HEX.search(r) for r in body), "preset %s: every token row carries a hex value" % k)

    accent = [r for r in body if re.search(r'accent|hero', cells(r)[0], re.I)]
    chk(len(accent) == 1,
        "preset %s: declares exactly one accent color (got %d)" % (k, len(accent)))

    def role(r):
        c = cells(r)
        return c[0] + ' ' + (c[2] if len(c) > 2 else '')
    verdict = {h.lower() for r in body if re.search(r'verdict|--go|--stop', role(r), re.I)
               for h in HEX.findall(r)}
    category = {h.lower() for r in body if re.search(r'accent|hero|axis|category', role(r), re.I)
                for h in HEX.findall(r)}
    if verdict:
        chk(bool(category) and not (verdict & category),
            "preset %s: verdict colors stay disjoint from accent/category colors" % k)

chk(re.search(r'field-proven|actually shipped|survived adversarial verification', src) is not None,
    "catalog states its presets are proven on real decks (provenance framing intact)")
chk(re.search(r'at least one real deployment', src) is not None,
    "promotion criterion still requires at least one real deployment")

print('\n'.join(out))
PY
PAL_OUT="$(python3 "$PAL_PY" "$PLUGIN/$GP/references/palette-presets.md" 2>&1)"; PAL_RC=$?
rm -f "$PAL_PY"
if [ "$PAL_RC" -ne 0 ] || [ -z "$PAL_OUT" ]; then
  # Never let a broken checker pass silently — an assertion block that runs zero assertions is a failure.
  check "palette invariant checker ran (python exit $PAL_RC): $PAL_OUT" 1
else
  while IFS='|' read -r st label; do
    [ -z "${label:-}" ] && continue
    [ "$st" = "OK" ] && check "$label" 0 || check "$label" 1
  done <<< "$PAL_OUT"
fi

echo
echo "================ PASS=$PASS  FAIL=$FAIL ================"
[ "$FAIL" -eq 0 ]
