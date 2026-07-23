# slide-craft

**읽는 지면**을 만드는 저작 스킬. 독자가 자기 페이스로 통째로 훑는 1장 완결 산출물 —
원페이저·보고 슬라이드·월차트·A3/A4 가로 PDF — 을 자립형 HTML로 만들고, 눈이 아니라
**계측으로** 완료를 판정한다.

타협하지 않는 두 가지만 고정이고 나머지는 선택제다.

1. **외부 리소스 0** — CDN·아이콘 웹폰트·원격 CSS/JS/이미지 금지. 사내망·오프라인에서
   외부 글리프는 전부 깨진 네모가 된다(실제 사고 이력). 아이콘 = 시스템 안전 글리프,
   장식 = 인라인 SVG, 폰트 = 시스템 폴백 스택.
2. **계측 전에는 완료가 아니다** — `scripts/slide_qa.py`를 통과해야 완료로 보고한다.

## 설치

```
/plugin marketplace add sungwooHa/skills-marketplace
/plugin install slide-craft@skills-marketplace
```

검증 스크립트에 Playwright가 필요하다 (HTML만 만들 거면 없어도 된다).

```bash
pip install playwright && playwright install chromium
```

## 아키타입 6종 — 선택 근거 = 지면 경제 + 독법

팔레트가 아니라 **지면 경제와 독법**이 다르기 때문에 별개 포맷이다.

| 아키타입 | 지면 경제 | 독법 |
|---|---|---|
| `overview-map` | 1장 · 시각 그룹 ≤5 · 전폭 | 상→하(지향·계층·기반) 또는 좌→우 흐름 |
| `timeline-roadmap` | 1장 · 공용 시간축 1개 × 레인 2~4 | 좌→우 달력순 (가로 좌표 = 데이터) |
| `report-set` | N장 · **장당 메시지 1개** · 단일 PDF로 배포 | 1→N · 세트를 한 문서로 |
| `comparison-matrix` | 1장 · 옵션 2~4 × 기준 4~7 + 판정 밴드 | 열(기준) 훑고 행(옵션) 하나에 착지 |
| `status-dashboard` | 1장 · 헤드라인 3~5 + 균일 타일 ≤12 | 큰 수치 먼저 → 타일 행 우선 스캔 |
| `process-flow` | 1장 · 체인 1개 또는 링 1개 | 화살표를 따라 (순환은 진입점·회전방향 명시) |

`SKILL.md`는 라우터다 — 아키타입을 고른 뒤 해당 `references/<아키타입>.md` **하나만** 읽는다.

## 검증 게이트

```bash
python3 <plugin>/skills/slide-craft/scripts/slide_qa.py <slide.html> --out /tmp/slide-qa
python3 <plugin>/skills/slide-craft/scripts/slide_qa.py <slide.html> --out /tmp/slide-qa \
        --pdf --page-size A3-landscape --expect-pages 1
```

하드 실패 항목 — 폰트 하한 미달 · 전폭 상자 점유율 미달 · 문서 경계 밖 잘림 ·
**외부 리소스 요청(네트워크 가로채기)** · 저명암비 · `--pdf` 시 PDF 페이지 수 불일치.
absolute 겹침은 보고만 하고 자동 실패시키지 않는다(의도적 레이어링이 있으므로 육안 판정).

**계측 통과 = 완료 아님.** 스크립트가 전체 PNG와 50% 축소 PNG를 남긴다. 둘 다 실제로 열어
위계·여백·겹침·포함관계를 눈으로 확인한 뒤 완료로 보고한다.

## 테마

색 의미는 스킬이 갖지 않는다. 프로젝트 루트에 `slide-theme.json`이 있으면 그 토큰이 이긴다
(`color.deep`·`color.accent`·`color.series[]`·`color.inactive`·`color.alert`, 선택으로
`semantics[]`·`flowRules`). 없으면 `references/theme.md`의 중립 기본값을 쓴다.
문안 어휘·금지어·톤도 스킬 소관이 아니다 — 소비 프로젝트의 기준 문서가 소유한다.

## deck-harness와의 경계

**중복이 아니라 산출물 클래스가 다르다.** 발표자가 서서 말하는 물건이면 이 스킬이 아니다 —
즉시 deck-harness의 `generate-presentation`으로 넘긴다.

| 축 | deck-harness | slide-craft |
|---|---|---|
| 산출물 | 16:9 덱 + 발표자 스크립트 뷰어 + PPTX | 1장 완결 HTML → A3/A4 가로 PDF |
| 소비 | 발표자 페이스 · 1장씩 노출 | 독자 페이스 · 전체 동시 노출 · 앞뒤 대조 |
| 밀도 교리 | 여백 ≥30% · 슬라이드당 ≤40단어 | 지면을 **채운다** · 데드스페이스 = 실패 |
| 레이아웃 자산 | 슬라이드 패턴 = 한 덱 포맷 **내부의** 장식 패턴 | 아키타입 = 지면 경제·독법이 다른 **별개 포맷** |
| 구동 | 9에이전트 PLAN→BUILD→VERIFY + 승인 게이트 | 게이트·에이전트 없는 경량 저작 |
| 의존성 | `python-pptx`·`beautifulsoup4`·`Pillow` | `playwright` 하나 |

편입하지 않는 이유는 두 가지다. ① deck-harness의 `build-verifier`는 `#deck .slide` 개수와
발표자 스크립트 파일 존재, PPTX 무결성을 전제하므로 1장 완결 지면에 걸면 **구조적으로 무조건
FAIL**이다. ② 밀도 교리가 정면 충돌해서, 한 플러그인 안에 "여백 30% 확보"와 "지면을 채워라"가
공존하면 에이전트가 어느 쪽을 집행할지 판정할 수 없다.

상호참조는 양방향으로 걸어둔다 — `SKILL.md` §Scope가 발표 신호를 감지하면
`generate-presentation`으로 핸드오프하고, `references/theme.md`는 deck-harness의
`palette-presets.md`를 테마 파생 소스로 안내한다.

## 출처

AX기반개발TF 프로젝트의 프로젝트 전용 스킬 `max-slide`를 일반화한 것이다.

| 축 | max-slide (프로젝트 전용) | slide-craft (범용) |
|---|---|---|
| 레이아웃 | 조감도 1종 고정 | 아키타입 6종 선택제 |
| 구조 | SKILL.md 111줄 전 규칙 인라인 | 라우터 + `references/` 지연 로딩 |
| 색 의미 | 도메인 색 하드코딩 | `slide-theme.json` 역할 토큰 |
| 검증 스크립트 | 스킬 **밖** 프로젝트 파일 | 번들 내장, 임의 경로 대상 실행 |
| 검증 게이트 | 폰트·점유율·겹침·잘림 | 위 + 외부 리소스 0 · 명암비 · PDF 페이지 수 |
| 프로젝트 경로 | 12곳 하드코딩 | 0 — "source-of-truth 문서" 추상 지칭만 |

문안·서사 기준(어휘·금지어·톤)은 의도적으로 가져오지 않았다. 소비 프로젝트의 기준 문서가
계속 소유한다 — 다른 프로젝트로 들고 가면 문안 판정은 그쪽에서 새로 정의해야 한다.

## 라이선스

MIT.
