# slide-craft — 읽히는 슬라이드의 문법

슬라이드가 안 읽히는 이유는 대개 미감이 아니라 **문법**이다. 주연이 둘이거나, 한 덩어리여야 할 정보가 카드 여섯 개로 쪼개져 있거나, 문장이 레이아웃에 욱여넣어져 불릿마다 두세 줄로 접힌다. 이 플러그인은 그 세 가지를 **수치로 판정 가능한 문법**으로 못 박고, 그 문법을 그대로 구현한 자립형 HTML 컴포넌트로 슬라이드를 조립한다.

수치는 취향이 아니다. 레퍼런스 슬라이드 3종을 1280×720으로 픽셀 재현해(수직 밴드 오차 ≤2px · 대표 문자열 폭 오차 ≤3.5%) 뽑아낸 실측값이다.

## 3축 문법

| 축 | 확인 질문 | 처방의 요체 |
|---|---|---|
| **콘텐츠 강약** | 제일 먼저 읽혀야 할 한 문장이 제일 크게 보이는가? | 주연 1개를 44px로 승격 + 키워드 1개소 하이라이트, 조연은 1행 메타로 강등 |
| **콘텐츠 그룹화** | 눈에 잡히는 시각 덩어리가 몇 개인가? | 동급 정보는 카드 경계를 지우고 한 컨테이너 안에서 구분선으로만 나눈다 |
| **글 가독성** | 불릿이 한 행에 끝나는가? | 안 끝나면 폰트가 아니라 **레이아웃을 바꾼다** (좁은 세로 카드 → 넓은 가로 카드) |

여기에 상수 하나가 붙는다 — **에셋 이미지 중심, 원본 그대로.** 사용자가 준 이미지는 자르지도, 보정하지도, 다시 만들지도 않는다. 이미지는 고정 블록이고 레이아웃이 그 블록을 피해 짜인다.

정본은 `references/design-grammar.md`. 증상 20종에 ID(`E-1`·`G-2`·`R-1`·`A-3` …)와 심각도(S1/S2/S3)가 붙어 있고, 처방마다 숫자가 달려 있다.

## 스킬

| 스킬 | 역할 | 요약 |
|---|---|---|
| `slide-craft` | **제작** | 원고 입력 → 문장 길이·정보 층 계측 → 문법이 허용하는 레이아웃 선택 → 컴포넌트 조립 → 렌더·자가 스크린샷 → 3축 자가 점검 |
| `slide-clinic` | **진단** | 렌더·계측 → 증상 ID로 적출 → 처방 리포트. **고치지 않는다** |

에이전트 `design-diagnostician`이 `slide-clinic`을 감싸 진단 전용 페르소나로 돌아간다. 제작과 판정을 분리한 이유는 하나다 — 자기 산출물을 자기가 채점하면 후하게 채점한다.

## 설치

```
/plugin marketplace add sungwooHa/skills-marketplace
/plugin install slide-craft@skills-marketplace
```

렌더·계측에 Playwright가 필요하다.

```
npm i playwright && npx playwright install chromium
```

## 사용

```
이 원고로 슬라이드 만들어줘            → slide-craft
이 장표 왜 안 읽히는지 진단해줘         → slide-clinic
리뷰 제출 전에 지면 점검해줘            → design-diagnostician
```

## 구성

```
references/
  design-grammar.md          문법 정본(SSOT) — 수치 스펙 · 3축 · 증상 20종 · 판정 체크리스트 · 성장 루프
  components/                자립형 HTML+inline CSS 블록 8종 (CDN·웹폰트·원격 이미지 없음)
    00-canvas · 01-eyebrow-headline · 02-meta-row · 03-icon-card-row
    04-stat-container · 05-dark-callout-image · 06-wide-card · 07-image-slot
  examples/                  조립 예시 4장 (축별 3장 + 스모크 테스트) — 회귀 기준선
scripts/
  shot.js                    Playwright 스크린샷 (.slide, 1280×720, DPR 1)
  measure.js                 계측 패스 — 타이포 스케일·팔레트 이탈·시각 덩어리 수·자동 줄바꿈·넘침
skills/  agents/
```

`examples/` 4장은 회귀 기준선이다. 문법 수치를 고친 뒤 이 4장이 FAIL로 뒤집히면, 규칙이 과한 것인지 예시가 낡은 것인지 판정하고 기록한다(`design-grammar.md` §5).

## 자립성

컴포넌트는 전부 인라인 CSS이고 외부 의존이 없다. 폰트는 시스템 한글 산세리프 스택(Pretendard → Apple SD Gothic Neo → Noto Sans KR → Malgun Gothic)으로 폴백하므로 네트워크 없이 동일하게 렌더된다.

## 성장 루프

새 before/after 사례가 들어오면 사례를 쌓지 않고 문법으로 증류한다 — 인입 → 기존 축 귀속 시도 → 독립 사례 2건 이상 재현 검증 → **수치화 가능성 확인**("답답해 보인다"는 문법이 아니다) → 증상·처방·수치·컴포넌트 4종 동시 갱신 → 기존 예시 회귀. 축 신설은 독립 사례 3건 이상일 때만, 하위 패턴 추가가 언제나 우선. 버전 규칙과 폐기 ID 처리는 `design-grammar.md` §6.

## 기존 플러그인과의 경계

- **deck-harness**: 발표덱 **프로그램** 제작(PLAN→BUILD→VERIFY, 발표자 스크립트·PPTX·5축 검증). slide-craft는 **한 장의 지면 문법** — 덱 안의 한 장을 다시 짜거나 보고 지면 단장을 만들 때. deck-harness 안에서 개별 장의 지면 품질 기준으로 이 문법을 참조해도 된다.
- **ui-review**: 제품 UI 소스 코드 검수. slide-craft/clinic의 대상은 슬라이드·보고 지면이다.
- **humanize-korean**: 문안의 AI 티 제거. 이 플러그인은 문안을 고치지 않는다 — 길이가 안 맞으면 원고를 고쳐 달라고 되돌린다.
- **strategy-report**: A4 인쇄용 보고서 + Word. 이쪽은 16:9 지면.
