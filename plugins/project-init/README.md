# project-init

**인터뷰 기반 프로젝트 부트스트래퍼.** 새 프로젝트에서 의도 우선 ≤4문항 인터뷰를 돌려
작은 spec(JSON)을 만들고, **결정론 생성기**가 자립형 프로젝트 뼈대를 찍어낸다.
철학은 마켓의 `starfield-studio`와 같다 — **같은 spec = 같은 프로젝트.** 코어는 LLM이 손으로
조립하지 않고 스크립트가 바이트 단위로 주입한다.

## 무엇을 만드나

생성물은 **완전 자립형**이다 — 운영 계약이 프로젝트 저장소 안에 박혀 있어 전역 설정
없는 머신에 클론해도 그대로 동작한다.

- `CLAUDE.md` — 상시 로드되는 **경계 있는 코어**(4대 기본원칙 + 운영 규율 + 라우팅 인덱스).
  커지지 않도록 설계됨. 크고 드문 상세는 에이전트 본문의 네이티브 점진 로딩에 태운다.
- `.claude/agents/advisor.md` — 3게이트(계획 검토·수용 검토·go/no-go) 자문관.
- `.claude/agents/<도메인명>.md` — 인터뷰에서 나온 **프로젝트 도메인명** 시드 에이전트(실행/검토/조사).
- `.claude/skill-feedback.md` — day 1부터 켜지는 스킬 강화 포착 파일.
- `.claude/project-init.spec.json` — 동결된 spec(재동기화 기준).

## 세 가지 모드

1. **project-init** [기본] — 인터뷰 → spec → 생성.
2. **machine-bootstrap** — 새 머신에서 스킬을 설치·사용 가능 상태로. 전역 섀시는 깔지 않는다.
3. **re-sync** — 정본(캐논)이 올라갔을 때 코어 블록만 재생성.

## 설치

```
/plugin marketplace add sungwooHa/skills-marketplace
/plugin install project-init@skills-marketplace
```

새 머신에서 한 번에:

```bash
bash "$CLAUDE_PLUGIN_ROOT/skills/project-init/scripts/bootstrap-machine.sh"
```

## 직접 실행 (생성기)

```bash
node "$CLAUDE_PLUGIN_ROOT/skills/project-init/scripts/scaffold.mjs" <spec.json> <target-dir> [--force]
```

`--force` 는 이미 초기화된 대상을 의도적으로 덮어쓸 때만(재동기화). 없이 실행하면 기존 `CLAUDE.md`
를 보호하며 거부한다.

## 불변식 (위반 금지)

- 생성물은 **자립형** — 어떤 전역 경로도 참조하지 않는다.
- 코어 `CLAUDE.md` 는 **커지지 않는다** — 경계 있는 상시 캐시.
- `model: opus` 는 **고정 불변식** — 프로젝트가 하향할 수 없다.
- 코어는 손으로 쓰지 않는다 — 스크립트가 주입. 고칠 곳은 `core.template.md`.

## 회귀 테스트

```bash
bash "$CLAUDE_PLUGIN_ROOT/skills/project-init/tests/init-test.sh"
```

`scaffold.mjs`·템플릿을 고친 뒤 반드시 GREEN(FAIL=0). 결정론·CANON 바이트 일치·기밀 스크럽을 함께 검증한다.

## 구성

```
plugins/project-init/
  .claude-plugin/plugin.json
  README.md
  skills/project-init/
    SKILL.md
    references/
      interview.md                 # ≤4문항 의도 우선 인터뷰 스크립트
      spec-schema.md               # spec JSON 스키마 + 예시
      core.template.md             # 생성될 CLAUDE.md 캐논 코어 (토큰 치환)
      skill-feedback.seed.md       # 강화 루프 포착 시드
      agent-templates/
        advisor.md                 # 3게이트 자문관 (바이트 복제)
        executor.md                # 실행형 스켈레톤 (model: opus)
        reviewer.md                # 비실행 판정형 스켈레톤
        researcher.md              # 외부 조사형 스켈레톤
    scripts/
      scaffold.mjs                 # 결정론 생성기 (node builtins, 무 npm 의존)
      bootstrap-machine.sh         # 새 머신 설치 (멱등·비파괴)
    tests/
      init-test.sh                 # 회귀 하네스 (PASS/FAIL)
      fixtures/example.spec.json   # 예시 spec
```
