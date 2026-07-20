#!/usr/bin/env bash
#
# Test suite for the Higgsfield spend gate (higgsfield-gate.js).
#
# Drives the hook script directly over stdin — no Claude Code involved — and
# asserts ALLOW (exit 0) vs BLOCK (exit 2) for every paid/free command shape
# against every token state.
#
# Run it after ANY edit to higgsfield-gate.js:
#     bash plugins/higgsfield/hooks/gate-test.sh
# Exits non-zero if a single assertion fails.
#
# When adding a command to FREE_PREFIXES / PAID_PREFIXES / MS_BILLING_GROUPS,
# add a case here in the same commit. A money gate that regresses silently is
# worse than no gate.
#
set -u
GATE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/higgsfield-gate.js"
SANDBOX="$(mktemp -d)"
mkdir -p "$SANDBOX/.claude"
TOKEN="$SANDBOX/.claude/.higgsfield-gate-approval.json"
PASS=0; FAIL=0

run() { # run <command-string> ; echoes ALLOW|BLOCK
  printf '{"session_id":"t","cwd":"%s","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":%s}}' \
    "$SANDBOX" "$(node -e 'process.stdout.write(JSON.stringify(process.argv[1]))' "$1")" \
  | ( cd "$SANDBOX" && CLAUDE_PROJECT_DIR="$SANDBOX" node "$GATE" 2>"$SANDBOX/err.txt" )
  [ $? -eq 2 ] && echo BLOCK || echo ALLOW
}

check() { # check <expected> <command>
  local got; got=$(run "$2")
  if [ "$got" = "$1" ]; then PASS=$((PASS+1)); printf '  ok   %-6s %s\n' "$got" "$2"
  else FAIL=$((FAIL+1)); printf '  FAIL exp=%s got=%s  %s\n' "$1" "$got" "$2"; fi
}

mktoken() { # mktoken <expires_offset_sec, "m" prefix = negative> <allowed> <used> <scope>
  node -e '
    const [off,allowed,used,scope,out]=process.argv.slice(1);
    const secs = off.startsWith("m") ? -Number(off.slice(1)) : Number(off);
    require("fs").writeFileSync(out, JSON.stringify({
      approved_at:new Date(Date.now()-60000).toISOString(),
      expires_at:new Date(Date.now()+secs*1000).toISOString(),
      runs_allowed:Number(allowed), runs_used:Number(used),
      estimated_credits:144, scope
    },null,2));' "$1" "$2" "$3" "$4" "$TOKEN"
}

echo "=== A. FREE commands — must ALWAYS pass (no token present) ==="
rm -f "$TOKEN"
for c in \
  "higgsfield generate cost seedance_2_0 --resolution 1080p" \
  "higgsfield generate cost workflow draw_to_video" \
  "higgsfield generate list --json" \
  "higgsfield generate get abc-123" \
  "higgsfield generate wait abc-123" \
  "higgsfield model list" \
  "higgsfield model get gpt_image_2" \
  "higgsfield workflow list" \
  "higgsfield workflow get reframe" \
  "higgsfield generate workflow cost reframe" \
  "higgsfield account status" \
  "higgsfield auth login" \
  "higgsfield soul-id list --soul-2" \
  "higgsfield soul-id get s-1 --json" \
  "higgsfield soul-id wait s-1 --timeout 45m" \
  "higgsfield upload create shoe1.png" \
  "higgsfield marketing-studio ad-formats list" \
  "higgsfield marketing-studio avatars list" \
  "higgsfield marketing-studio brand-kits fetch --url https://x.com" \
  "higgsfield marketing-studio products create --name shoe" \
  "higgsfield marketing-studio hooks list" \
  "higgsfield marketing-studio settings list" \
  "higgsfield marketing-studio ad-references list" \
  "higgsfield marketing-studio ad-references get r-1 --json" \
  "higgsfield marketing-studio products get p-1" \
  "higgsfield marketing-studio brand-kits get b-1 --json" \
  "higgsfield marketing-studio avatars get a-1" \
  "higgsfield generate create --help" \
  "higgsfield soul-id create --help" \
  "higgsfield marketing-studio dtc-ads generate --cost-only --product p1" \
  "higgsfield --help" \
  "ls -la && echo hello" \
  "git status" \
  ; do check ALLOW "$c"; done

echo
echo "=== B. PAID commands — no token => BLOCK ==="
rm -f "$TOKEN"
for c in \
  "higgsfield generate create seedance_2_0 --prompt 'x' --wait" \
  "higgsfield generate create gpt_image_2 --prompt 'storyboard' --resolution 2k" \
  "higgsfield generate workflow draw_to_video --image a.png" \
  "higgsfield generate workflow reframe --video v.mp4" \
  "higgsfield soul-id create --name Alice --soul-2 --image a.png" \
  "higgsfield marketing-studio dtc-ads generate --product p1 --avatar a1" \
  "higgsfield marketing-studio ad-references create --video-input u-1" \
  "REF_ID=\$(higgsfield marketing-studio ad-references create --job J1 --json | jq -r .id)" \
  "higgsfield product-photoshoot create --product p1" \
  "higgsfield marketplace-cards create --product p1" \
  "/usr/local/bin/higgsfield generate create seedance_2_0 --prompt 'x'" \
  "cd /tmp && higgsfield generate create seedance_2_0 --prompt 'x'" \
  "ID=\$(higgsfield generate create gpt_image_2 --prompt 'x' --json)" \
  "higgsfield generate list && higgsfield generate create seedance_2_0 --prompt 'x'" \
  "higgsfield generate create seedance_2_0 --prompt 'run --help please'" \
  "higgsfield generate create seedance_2_0 --prompt \"a --cost-only b\"" \
  "higgsfield generate create seedance_2_0 --prompt 'a && higgsfield --help'" \
  ; do check BLOCK "$c"; done

echo
echo "=== C. Unrecognized higgsfield subcommand => BLOCK (fail closed) ==="
rm -f "$TOKEN"
for c in \
  "higgsfield brand-new-paid-thing --go" \
  "higgsfield marketing-studio dtc-ads create --product p1" \
  ; do check BLOCK "$c"; done

echo
echo "=== D. Valid token (30min, 3 runs, scope=seedance_2_0) ==="
mktoken 1800 3 0 seedance_2_0
check ALLOW "higgsfield generate create seedance_2_0 --prompt 'x' --wait"
echo "  runs_used now: $(node -pe 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).runs_used' "$TOKEN")"
check ALLOW "higgsfield generate create seedance_2_0 --prompt 'y' --wait"
echo "  runs_used now: $(node -pe 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).runs_used' "$TOKEN")"
check ALLOW "higgsfield generate create seedance_2_0 --prompt 'z' --wait"
echo "  runs_used now: $(node -pe 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).runs_used' "$TOKEN")"
echo "  -- 4th run exceeds runs_allowed=3 --"
check BLOCK "higgsfield generate create seedance_2_0 --prompt 'w' --wait"
echo "  free command still passes on a spent token:"
check ALLOW "higgsfield generate list --json"

echo
echo "=== E. Scope mismatch => BLOCK ==="
mktoken 1800 3 0 seedance_2_0
check BLOCK "higgsfield soul-id create --name Alice --soul-2 --image a.png"
check ALLOW "higgsfield generate create seedance_2_0 --prompt 'x'"

echo
echo "=== F. Expired token => BLOCK ==="
mktoken m60 3 0 seedance_2_0
check BLOCK "higgsfield generate create seedance_2_0 --prompt 'x'"
check ALLOW "higgsfield generate cost seedance_2_0"

echo
echo "=== G. Malformed / hostile token => BLOCK (fail closed) ==="
echo 'not json{' > "$TOKEN";                    check BLOCK "higgsfield generate create seedance_2_0 --prompt 'x'"
echo '{}' > "$TOKEN";                           check BLOCK "higgsfield generate create seedance_2_0 --prompt 'x'"
mktoken 1800 3 0 "";                            check BLOCK "higgsfield generate create seedance_2_0 --prompt 'x'"
node -e 'require("fs").writeFileSync(process.argv[1],JSON.stringify({expires_at:new Date(Date.now()+9e5).toISOString(),runs_allowed:"lots",runs_used:0,scope:"*"}))' "$TOKEN"
                                                check BLOCK "higgsfield generate create seedance_2_0 --prompt 'x'"
echo "  free command still passes with a corrupt token on disk:"
echo 'not json{' > "$TOKEN";                    check ALLOW "higgsfield model list"

echo
echo "=== H. Two paid segments consume two runs ==="
mktoken 1800 2 0 seedance_2_0
check ALLOW "higgsfield generate create seedance_2_0 --prompt 'a' && higgsfield generate create seedance_2_0 --prompt 'b'"
echo "  runs_used now: $(node -pe 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).runs_used' "$TOKEN")"
check BLOCK "higgsfield generate create seedance_2_0 --prompt 'c'"
echo "  -- 2 paid segments against a 1-run approval --"
mktoken 1800 1 0 seedance_2_0
check BLOCK "higgsfield generate create seedance_2_0 --prompt 'a' && higgsfield generate create seedance_2_0 --prompt 'b'"

echo
echo "=== L. ad-references create is GATED, not banned (approved estimate unblocks it) ==="
mktoken 1800 1 0 "ad-references create"
check ALLOW "higgsfield marketing-studio ad-references create --video-input u-1"
echo "  runs_used now: $(node -pe 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).runs_used' "$TOKEN")"
check BLOCK "higgsfield marketing-studio ad-references create --video-input u-2"
echo "  polling stays free on a spent token:"
check ALLOW "higgsfield marketing-studio ad-references get r-1 --json"
check ALLOW "higgsfield marketing-studio ad-references list"

echo
echo "=== I. Non-Bash tool payload passes through ==="
printf '{"tool_name":"Write","tool_input":{"file_path":"/x","content":"higgsfield generate create seedance_2_0"}}' \
  | ( cd "$SANDBOX" && node "$GATE" >/dev/null 2>&1 )
[ $? -eq 0 ] && { PASS=$((PASS+1)); echo "  ok   ALLOW  (Write tool, not gated)"; } || { FAIL=$((FAIL+1)); echo "  FAIL Write tool was gated"; }

echo
echo "=== J. Garbage stdin: higgsfield-flavoured => BLOCK, plain => ALLOW ==="
printf 'not json at all higgsfield generate create' | node "$GATE" >/dev/null 2>&1
[ $? -eq 2 ] && { PASS=$((PASS+1)); echo "  ok   BLOCK  (unparseable payload mentioning higgsfield)"; } || { FAIL=$((FAIL+1)); echo "  FAIL failed open on unparseable higgsfield payload"; }
printf 'not json at all' | node "$GATE" >/dev/null 2>&1
[ $? -eq 0 ] && { PASS=$((PASS+1)); echo "  ok   ALLOW  (unparseable payload, unrelated)"; } || { FAIL=$((FAIL+1)); echo "  FAIL blocked an unrelated command"; }

echo
echo "=== K. Sample block message ==="
rm -f "$TOKEN"
printf '{"cwd":"%s","tool_name":"Bash","tool_input":{"command":"higgsfield generate create seedance_2_0 --prompt x"}}' "$SANDBOX" \
  | ( cd "$SANDBOX" && CLAUDE_PROJECT_DIR="$SANDBOX" node "$GATE" ) 2>&1 | sed 's/^/  | /'

echo
echo "================ PASS=$PASS  FAIL=$FAIL ================"
rm -rf "$SANDBOX"
[ "$FAIL" -eq 0 ]
