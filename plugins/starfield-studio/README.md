# starfield-studio

[![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-D97757?logo=anthropic&logoColor=white)](https://github.com/sungwooHa/skills-marketplace)
[![version](https://img.shields.io/badge/version-1.0.0-informational)](./.claude-plugin/plugin.json)
[![skills](https://img.shields.io/badge/skills-1-4C9A2A)](#워크플로)
[![gate](https://img.shields.io/badge/gate-콘티%20승인-ff6b35)](#콘티-승인-게이트)
[![cost](https://img.shields.io/badge/cost-무료%20(로컬%20렌더)-blue)](#요구-사항)
[![license](https://img.shields.io/badge/license-MIT-blue)](../../LICENSE)

별(스타필드) **모션 에셋 제작 스킬**. 연출 의도를 spec(JSON)으로 기술하고, 콘티 HTML로 승인받은 뒤,
로컬에서 결정론적으로 GIF/MP4를 렌더합니다. 키노트 배경·브릿지 컷·루프 배경용 에셋을 만들 때 씁니다.

## 이 스킬의 두 가지 설계 규칙

**① 의도는 spec 에만 산다 — 파생 HTML 복제 금지.**
엔진 HTML은 스킬 안에 **딱 하나**(`assets/engine_template.html`)입니다. 연출마다 HTML을 복사·수정하는 방식은
금지합니다 — 코드 복제 = 의도 소실 = 재현 불가. "이 별 HTML 좀 고쳐줘"라는 요청도 **spec 을 고쳐 다시 빌드**하는
것으로 답합니다. 산출된 콘티 HTML을 직접 손대지 않습니다.

**② 같은 spec = 같은 픽셀.**
시드 PRNG + 고정 스텝이라 콘티(브라우저)에서 본 프레임과 렌더된 GIF가 프레임 단위로 동일합니다
(두 번 렌더해 md5 일치 확인). 마우스 같은 비결정 요소가 없습니다. 그래서 **렌더가 이상하면 원인은 항상 spec**이며,
콘티를 먼저 봅니다.

## 콘티 승인 게이트

**승인 전 렌더 금지.** 스킬은 spec → 콘티 HTML을 만들어 사용자에게 보여주고, 승인을 받은 뒤에만 렌더합니다.
수정 요청이 오면 spec을 고쳐 다시 빌드하고 재승인을 받습니다.

로컬 렌더라 **과금이 없으므로 견적 게이트는 없습니다**(180프레임 ≈ 2초). 이 게이트는 돈이 아니라 **연출**을
확인받기 위한 것입니다. `higgsfield` 플러그인과 달리 PreToolUse 훅이 없습니다 — 지출 경로가 없기 때문입니다.

## 워크플로

```
의도 청취 → spec(JSON) 작성 → 콘티 빌드 → [승인] → 렌더 → GIF/MP4
                    ↑                              │
                    └──────── 수정 요청 ────────────┘
```

| 사용자 표현 | 프리미티브 |
|---|---|
| "광원 하나가 지나가게" | `orbs` (경로·꼬리·주변 별 밝힘) |
| "특정 구간만 반짝이게" | `pulses` (시간창 × 공간 존) |
| "별들이 심볼/로고로 모이게" | `timeline`의 `progress` (+ `align.paths`로 로고 교체) |
| "별들이 글자를 만들게" (한글 포함) | `groups[].text` — 실제 폰트 래스터화 |
| "장면 여러 개가 심리스하게" | 하나의 긴 spec + `--split "6,12"` |
| "피날레에 중앙 수축" | `timeline`의 `collapse` |
| "잔잔한 배경 무한 루프" | `loop: true` (완전 루프 보장) |

스펙 스키마·레시피 전문은 [`skills/starfield-studio/references/spec-guide.md`](./skills/starfield-studio/references/spec-guide.md).
바로 돌려볼 수 있는 예제 spec 2종이 [`skills/starfield-studio/examples/`](./skills/starfield-studio/examples/)에 들어 있습니다.

## 설치

```
/plugin marketplace add sungwooHa/skills-marketplace
/plugin install starfield-studio@skills-marketplace
```

- 업데이트: `/plugin marketplace update skills-marketplace`
- 제거: `/plugin uninstall starfield-studio`

## 요구 사항

렌더러(`scripts/render.mjs`)는 **npm 의존성이 0**이지만, 아래 세 가지를 **로컬 시스템에서** 찾습니다.
없으면 렌더 단계에서 실패합니다 (콘티 빌드는 Node만 있으면 됩니다).

| 필요한 것 | 왜 | 없으면 |
|---|---|---|
| **Node.js 22+** | 내장 `WebSocket`(CDP 통신)을 씁니다. Node 20에는 전역 `WebSocket`이 없습니다 | 콘티 빌드·렌더 모두 불가 |
| **Chrome / Chromium** | 헤드리스 Chrome을 CDP로 띄워 canvas 프레임을 PNG로 캡처합니다 | `Chrome/Chromium 을 찾지 못했습니다` 후 종료 |
| **ffmpeg** (PATH에) | PNG 시퀀스 → GIF(palettegen/paletteuse) · MP4(libx264) 조립 | `ffmpeg 실패` 또는 `ENOENT` 후 종료 |

**Chrome 탐색 순서** — `render.mjs`는 ① `$CHROME_BIN` ② `/Applications/Google Chrome.app/...`(macOS 고정 경로)
③ `~/Library/Caches/ms-playwright/chromium_headless_shell*`(macOS) 순으로 찾습니다.

> ⚠️ **탐색 경로가 macOS 전용입니다.** Linux·WSL이거나, macOS라도 Chrome을 기본 위치에 두지 않았다면
> **`CHROME_BIN`을 반드시 지정해야 합니다.** 자동 탐색은 실패합니다.

```bash
# Linux / WSL, 또는 비표준 위치의 Chrome
export CHROME_BIN=/usr/bin/chromium        # 또는 google-chrome 등 실제 경로

# 브라우저가 아예 없을 때 (Playwright 캐시에 헤드리스 셸만 받기)
npx playwright install chromium

# ffmpeg
brew install ffmpeg      # macOS
sudo apt install ffmpeg  # Debian/Ubuntu
```

렌더는 Chrome을 임시 `--user-data-dir`로 띄우고 프레임 캡처가 끝나면 종료·정리합니다. 네트워크는 쓰지 않습니다
(콘티 HTML은 자립형 `file://` 로드).

## 프로젝트별 설정 (`.claude/starfield-studio.local.md`) — 선택

작업 디렉터리만 프로젝트마다 주입합니다. 기본값으로 충분하면 파일을 만들 필요가 없습니다.

| 키 | 기본값 | 효과 |
|---|---|---|
| `asset_root` | `starfield_studio` | `specs/`·`conti/`·`out/` 의 상위 디렉터리 (프로젝트 루트 기준 또는 절대경로) |

```
asset_root: 00_ASSET/starfield_studio
```

템플릿: [`starfield-studio.local.md.example`](./starfield-studio.local.md.example).
`conti/`·`out/` 산출물은 spec에서 언제든 재생성되므로 gitignore를 권합니다.

## 알려진 제약

- **`loop: true`와 `timeline`의 progress/collapse는 병용 불가.** 루프 모드는 물리 적분 없이 해석적(Lissajous)
  드리프트로 동작하므로 수렴·수축이 무시됩니다. 위반 시 콘티 상단에 경고가 표시됩니다.
- **GIF 알파는 1비트**입니다. `bg: "transparent"`로 만든 에셋은 부드러운 헤일로가 알파 임계에서 잘립니다 —
  둥근 광원 에셋은 원 안쪽에 어두운 배경을 구워 넣는 편이 낫습니다(`mask` + 불투명 `bg`).
- **텍스트 정렬(`groups[].text`)은 보는 브라우저의 폰트 엔진으로 래스터화**됩니다. 콘티↔렌더 픽셀 일치를 보장하려면
  콘티도 렌더러와 같은 Chrome에서 확인하세요. 기본 폰트 스택은 macOS 계열(`-apple-system`,
  `Apple SD Gothic Neo`)이라 다른 OS에서는 글자 모양이 달라질 수 있습니다 — `groups[].text.font`로 지정하세요.

## 구성

```
plugins/starfield-studio/
  .claude-plugin/plugin.json
  README.md
  starfield-studio.local.md.example   # asset_root 주입 템플릿 (선택)
  skills/starfield-studio/
    SKILL.md                          # 워크플로 · 콘티 게이트 · 제약
    references/spec-guide.md          # spec 스키마 전문 · 레시피
    assets/engine_template.html       # 단 하나의 엔진 (여기만 수정)
    examples/demo_light_sweep.spec.json
    examples/demo_converge_finale.spec.json
    scripts/build_conti.mjs           # spec → 자립형 콘티 HTML
    scripts/render.mjs                # 콘티 → 프레임 PNG → GIF/MP4
```
