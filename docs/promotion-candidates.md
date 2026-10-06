<!-- 2026-10-06 리뉴얼 세션 산출. 글로벌 환경 정리 중 프로젝트 레벨 스킬·에이전트를 스윕한 결과. 승격 판단은 docs/loop.md 게이트를 따른다. -->
# 프로젝트 레벨 skills/agents/commands 승격 후보 스윕 (읽기 전용, 2026-10-06)

스캔: `~/workspace` maxdepth 5, worktrees/node_modules/graphify-out/skills-marketplace 제외. InAX 포함. 심볼릭 링크 skill은 대상 해석 후 집계.

## 승격 후보 (2개 이상 프로젝트에 같은 이름)

| 이름 | 종류 | 프로젝트 목록 | 내용 동일? | description |
|---|---|---|---|---|
| humanize-korean | skill | `05 PM`, `02 lab/im-not-ai` | 다름 | AI가 쓴 한글 텍스트를 "사람이 쓴 글처럼" 윤문하는 오케스트레이터 |
| humanize-monolith | agent | `05 PM`, `02 lab/im-not-ai` | 다름 (v1.6.1 vs v1.5) | Fast Path 단일 호출 윤문 에이전트 |
| ai-tell-detector | agent | `05 PM`, `02 lab/im-not-ai` | 동일 | 한글 AI 티 10대분류×40+ 패턴 구간 탐지 → JSON |
| content-fidelity-auditor | agent | `05 PM`, `02 lab/im-not-ai` | 동일 | 원문·윤문본 의미 단위 대조, 롤백 지시 |
| korean-ai-tell-taxonomist | agent | `05 PM`, `02 lab/im-not-ai` | 동일 | AI 티 패턴 분류·확장·버전 관리 |
| korean-style-rewriter | agent | `05 PM`, `02 lab/im-not-ai` | 동일 | 탐지 리포트 기반 수술적 윤문 |
| naturalness-reviewer | agent | `05 PM`, `02 lab/im-not-ai` | 동일 | 윤문본 자연스러움·과윤문 판정 |
| max-slide | skill | `05 PM`, `00 product/04. AX기반개발/00 기획` | 다름 | THE MAX 조감도 스타일 경영진 보고 슬라이드(1600px HTML) |
| report-producer | agent | `05 PM`, `00 product/04. AX기반개발/00 기획` | 다름 | 보고자료 원고(SSOT)→맥락→산출물 제작 |
| report-writer | agent | `05 PM`, `00 product/04. AX기반개발/00 기획` | 다름 | 보고서 초안 작성 |
| slide-producer | agent | `05 PM`, `00 product/04. AX기반개발/00 기획` | 다름 | 확정 원고→슬라이드 세트 HTML→PDF, 4게이트 PASS |
| slide-qa-auditor | agent | `05 PM`, `00 product/04. AX기반개발/00 기획` | 다름 | slide_qa.py 계측 + PNG + 문안 대조 4게이트 |
| visual-designer | agent | `05 PM`, `00 product/04. AX기반개발/00 기획` | 다름 | 대시보드·구조도·로드맵 HTML 시각화 |
| alignment-tracker | agent | `05 PM`, `00 product/04. AX기반개발/00 기획` | 다름 | 성과관리 축 협의 필요·미확정 지점 관리 (프로젝트 특화) |
| add-spec | skill | `02 lab/project-harness`, `01 ops/exd-plan-mockup`, `00 product/02. ONSITE AI/onsite-plan/planning-workspace` | 다름 | 프로토타입에 기획서 오버레이(마커+스펙 패널) 추가 |
| export-prototype | skill | 위 3곳 동일 | 일부 동일 (harness·exd 동일, planning-workspace 다름) | 프로토타입 단일 HTML 병합 |
| generate-prototype | skill | 위 3곳 동일 | 다름 (3개 모두 상이) | 유저 플로우 기반 화면별 HTML 와이어프레임 |
| produce-design | skill | 위 3곳 동일 | 다름 | 비주얼 완성도·목업 콘텐츠·GIF 제작 |
| review-ux | skill | 위 3곳 동일 | 다름 | 프로토타입 UX 분석·개선 |
| sync-design-system | skill | 위 3곳 동일 | 다름 | Figma MCP로 design-system.css 동기화 |
| wrap-up | skill | 위 3곳 동일 | 동일 | 오늘 작업 랩업 출력 |
| init-project | skill | `02 lab/project-harness`, `01 ops/exd-plan-mockup` | 다름 | 프로젝트 하네스 템플릿 초기화 |
| design-critic | agent | `00 product/04. AX기반개발/01 research`, `03 docs/자기소개/Presentation-Harness` | 다름 (서로 다른 용도) | 전자: 설계안 비평 / 후자: 발표 디자인 비평 — 이름만 충돌 |
| research-auditor | agent | `00 product/04. AX기반개발/01 research`, `00 product/04. AX기반개발/00 기획` | 다름 | 01 research 문서 규약·정합성 감사 (프로젝트 특화) |

## 유사 후보 (이름은 다르지만 description이 겹침)

| 이름들 | 프로젝트 | 겹치는 점 |
|---|---|---|
| humanize / humanize-redo (skill) vs humanize / humanize-redo (command) | `05 PM`(skill) ↔ `02 lab/im-not-ai`(command) | 같은 윤문 진입점·2차 윤문을 skill/command로 각각 구현. 플러그인 `humanize-korean`과도 중복 |
| report-writer / report-producer / slide-producer / slide-qa-auditor | `05 PM`, `00 기획` | 보고·슬라이드 제작·검증 파이프라인(같은 계열, 문안만 프로젝트별 분기) |
| slide-qa-auditor vs slide-design-reviewer vs design-reviewer vs design-critic | `05 PM`/`00 기획`, `03 docs/26H1_가개기실_워크샵`, `03 docs/design`, `Presentation-Harness` | 슬라이드·발표 디자인 검수 전담. 마켓플레이스 `slide-craft:design-diagnostician`/`deck-harness:design-critic`과도 겹침 |
| max-slide / make-slide / slide-composer / slide-composition / slide-layout-patterns | `00 기획`·`05 PM`, `03 docs/ppt-design`, `03 docs/design`, `Presentation-Harness` | 슬라이드 HTML 생성·레이아웃. `slide-craft:slide-craft`와 중복 |
| generate-presentation / presentation-orchestrator | `Presentation-Harness`, `03 docs/design` | 발표자료 풀 파이프라인 오케스트레이터 (generate-presentation은 `deck-harness`로 이미 플러그인화) |
| audience-strategist / audience-analysis, narrative-architect / narrative-structuring, visual-director / visual-design-system | `03 docs/design` | 같은 도메인의 agent(역할)와 skill(방법) 쌍. deck-harness의 presentation-strategist/design-director와 겹침 |
| pdf-analyze / pdf-analysis / doc-analysis | `onsite-ai-verify`, `05. InAX/apps/agent` | PDF·문서 분석 |
| inax-api-architect / inax-api-contract-architect | `05. InAX` | API 설계 계열 (InAX 전용) |
| onsite-mockup / add-mockup-viewer / generate-prototype | `onsite-plan`, `project-harness` | 목업·프로토타입 HTML 생성 |
| verify-implementation / verify-plan / inax-verify-screen / verify-publish | `05. InAX` | 검증 계열 (InAX 전용, 범용화 후보는 verify-implementation·verify-plan) |

## 프로젝트별 보유 현황

| 프로젝트 | skills | agents | commands | hooks |
|---|---|---|---|---|
| `05 PM` | 4 | 16 | 0 | 없음 |
| `00 product/01. ONSITE/cshm-worm-onsite` | 1 | 3 | 0 | 없음 |
| `00 product/01. ONSITE/onsite` | 0 | 0 | 7 | 있음 |
| `00 product/02. ONSITE AI/onsite-plan` | 1 | 0 | 0 | 없음 |
| `00 product/02. ONSITE AI/onsite-plan/onsite-ai-verify` | 3 | 0 | 0 | 없음 |
| `00 product/02. ONSITE AI/onsite-plan/planning-workspace` | 7 | 0 | 0 | 없음 |
| `00 product/04. AX기반개발/00 기획` | 2 | 12 | 0 | 있음 |
| `00 product/04. AX기반개발/01 research` | 4 | 6 | 0 | 있음 |
| `00 product/05. InAX` | 30 (대부분 symlink) | 1 | 3 | 있음 |
| `00 product/05. InAX/apps/agent` | 11 | 0 | 0 | 없음 |
| `01 ops/exd-plan-mockup` | 8 | 0 | 0 | 없음 |
| `02 lab/esp32-inclinometer-demo` | 0 | 1 | 0 | 있음 |
| `02 lab/im-not-ai` | 1 | 7 | 2 | 없음 |
| `02 lab/project-harness` | 10 | 0 | 0 | 없음 |
| `03 docs/26H1_가개기실_워크샵` | 0 | 3 | 0 | 있음 |
| `03 docs/design` | 6 | 5 | 0 | 없음 |
| `03 docs/ppt-design` | 1 | 0 | 0 | 없음 |
| `03 docs/자기소개/Presentation-Harness` | 4 | 9 | 0 | 없음 |

## 프로젝트 훅 현황

| 프로젝트 | 이벤트 | matcher | 명령(파일명) |
|---|---|---|---|
| `02 lab/esp32-inclinometer-demo` | PreToolUse | Bash | docsync-gate.py |
| `00 product/05. InAX` | Stop | - | stop.sh |
| `00 product/05. InAX` | Stop | - | session-state-stop.sh |
| `00 product/04. AX기반개발/01 research` | PostToolUse | Write\|Edit | notation_guard.sh |
| `00 product/04. AX기반개발/00 기획` | PostToolUse | Write\|Edit | humanize_report_hook.sh |
| `00 product/04. AX기반개발/00 기획` | PreToolUse | Bash | (인라인 python/case 스크립트, grep 관련 가드) |
| `00 product/04. AX기반개발/00 기획` | PreToolUse | Read\|Glob | (인라인 python 스크립트, 코드 확장자 탐지) |
| `00 product/01. ONSITE/onsite` (settings.json) | PostToolUse | Edit\|Write | classify-change.py |
| 〃 | PostToolUse | Bash | track-sync.py |
| 〃 | PreToolUse | Bash | pre-commit-gate.py |
| 〃 | Stop | - | session-summary.py |
| `00 product/01. ONSITE/onsite` (settings.local.json) | PreToolUse | Bash | check-dev-report.py, gate_advisory.py |
| 〃 | PostToolUse | Bash | collect.py |
| `03 docs/26H1_가개기실_워크샵` | PreToolUse | Bash | log-sync-gate.sh |
| 〃 | UserPromptSubmit | - | feedback-capture.sh |
| 〃 | SessionStart | - | feedback-reflect.sh |

## 메모

- 깨진 symlink 2건: `00 product/05. InAX/.claude/skills/docs-search`, `inax-design-system` (대상 `../../.agents/skills/...` 미존재). 나머지 InAX skill 28개도 같은 `.agents/skills`로의 symlink이므로 실체는 InAX 루트의 `.agents/skills`이며 승격 시 그쪽을 기준으로 해야 함.
- `05 PM`·`02 lab/im-not-ai`의 humanize 계열(skill 3·agent 6·command 2)은 마켓플레이스 플러그인 `humanize-korean`(v2.0.0)의 구버전(v1.5/v1.6.1) 사본으로 보임 → 승격보다 폐기·플러그인 교체 대상. `03 docs/자기소개/Presentation-Harness`의 generate-presentation, design-critic 등도 `deck-harness` 플러그인과 이름이 겹치는 사본.
- `05 PM`과 `00 기획`의 보고·슬라이드 agent 6종은 같은 이름이나 내용이 프로젝트 맥락(성과관리 vs TF 보고)으로 분기됨. 승격하려면 프로젝트 특화 부분 분리 필요. `05 PM`은 프로젝트 루트가 `~/workspace/05 PM`.
