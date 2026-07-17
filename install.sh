#!/usr/bin/env bash
# skills-marketplace — 특정 스킬만 로컬 심링크 설치(선택적 편의 스크립트).
# 권장 설치법은 Claude Code 마켓플레이스: /plugin marketplace add sungwooHa/skills-marketplace
# 이 스크립트는 클론 후 원하는 스킬만 ~/.claude/skills 에 직접 연결하고 싶을 때 사용한다.
#
#   ./install.sh                 # 사용 가능한 스킬 목록 출력
#   ./install.sh travel-proposal # 지정 스킬만 심링크 설치 (여러 개 나열 가능)
#   ./install.sh --all           # 전부 설치
#   옵션: --copy(복사) --force(백업 후 덮어씀) --dry-run
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
PLUGINS_DIR="$REPO/plugins"
MODE=symlink; FORCE=0; DRYRUN=0; ALL=0
TS="$(date +%Y%m%d-%H%M%S)"
NAMES=()

for a in "$@"; do
  case "$a" in
    --copy) MODE=copy ;;
    --force) FORCE=1 ;;
    --dry-run) DRYRUN=1 ;;
    --all) ALL=1 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    -*) echo "unknown arg: $a" >&2; exit 2 ;;
    *) NAMES+=("$a") ;;
  esac
done

list_skills() { for d in "$PLUGINS_DIR"/*/; do [ -d "$d" ] && basename "$d"; done; }

if [ "$ALL" = 0 ] && [ ${#NAMES[@]} -eq 0 ]; then
  echo "사용 가능한 스킬:"; list_skills | sed 's/^/  - /'
  echo; echo "설치: ./install.sh <이름> [이름...]  또는  --all"; exit 0
fi
[ "$ALL" = 1 ] && while IFS= read -r n; do NAMES+=("$n"); done < <(list_skills)

run() { echo "+ $*"; [ "$DRYRUN" = 1 ] || "$@"; }

install_skill() {
  local name="$1"
  local skdir="$PLUGINS_DIR/$name/.claude/skills"
  [ -d "$skdir" ] || { echo "없음: $name ($skdir)"; return 1; }
  for s in "$skdir"/*/; do
    local sk; sk="$(basename "$s")"
    local dest="$CLAUDE_HOME/skills/$sk" src="${s%/}"
    run mkdir -p "$CLAUDE_HOME/skills"
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then echo "ok (already linked): $dest"; continue; fi
    if [ -e "$dest" ]; then
      if [ "$FORCE" = 1 ] || [ -L "$dest" ]; then run mv "$dest" "$dest.bak.$TS"
      else echo "refuse: $dest 존재 (--force 또는 --copy)"; continue; fi
    fi
    case "$MODE" in symlink) run ln -s "$src" "$dest" ;; copy) run cp -RL "$src" "$dest" ;; esac
    echo "installed: $dest"
  done
}

for n in "${NAMES[@]}"; do echo "== $n =="; install_skill "$n"; done
echo; echo "완료 (mode=$MODE). 새 세션에서 스킬 발동."
