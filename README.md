# skills-marketplace

[![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin%20marketplace-D97757?logo=anthropic&logoColor=white)](https://github.com/sungwooHa/skills-marketplace)
[![skills](https://img.shields.io/badge/skills-2-4C9A2A)](#수록-스킬)
[![license](https://img.shields.io/badge/license-MIT-blue)](./LICENSE)
[![platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20WSL-lightgrey)](#요구-사항)
[![stars](https://img.shields.io/github/stars/sungwooHa/skills-marketplace?style=social)](https://github.com/sungwooHa/skills-marketplace/stargazers)

sungwooHa의 개인 **Claude Code 스킬 마켓플레이스**. 목적별 스킬을 한 레포에 모아두고, 필요한 것만 골라 설치합니다.

## 설치 (필요한 스킬만)

마켓플레이스를 한 번 등록한 뒤, 원하는 플러그인만 설치합니다.

```
/plugin marketplace add sungwooHa/skills-marketplace
/plugin install travel-proposal@skills-marketplace
```

- 목록 보기: `/plugin marketplace` → skills-marketplace 선택
- 업데이트: `/plugin marketplace update skills-marketplace`
- 제거: `/plugin uninstall travel-proposal`

클론해서 스크립트로 특정 스킬만 심링크하고 싶으면:

```bash
git clone https://github.com/sungwooHa/skills-marketplace.git
cd skills-marketplace
./install.sh travel-proposal        # 이름 나열 (없으면 목록 출력)
```

## 수록 스킬

| 스킬 | 설명 |
|---|---|
| [**travel-proposal**](./plugins/travel-proposal) | 여행 기획서를 오프라인 자립형 인터랙티브 HTML(주제탭·지도·카드·Airbnb 디자인)로 제작. 한국어 개조식. |
| [**higgsfield**](./plugins/higgsfield) | Higgsfield 영상·이미지 생성 4스킬 번들. 콘티(G1) → 견적(G3) → 생성 게이트 체인 + Soul 레퍼런스 학습. 무콘티·무견적 생성 금지. |

각 스킬의 상세 설명·스크린샷은 해당 스킬 폴더의 README를 참고하세요.

_(스킬은 계속 추가됩니다.)_

## 새 스킬 추가하는 법

1. `plugins/<plugin-name>/` 폴더를 만들고 그 안에:
   - `.claude-plugin/plugin.json` (name·version·description — `skills` 경로 필드는 불필요)
   - `skills/<skill-name>/SKILL.md` (+ 필요하면 `references/`). `skills/` 하위는 **자동 탐색**되며,
     한 플러그인에 스킬 여러 개를 둘 수 있습니다 (예: `higgsfield` 4종).
2. 루트 `.claude-plugin/marketplace.json` 의 `plugins[]` 에 한 항목 추가:
   ```json
   { "name": "<plugin-name>", "source": "./plugins/<plugin-name>", "description": "...", "version": "1.0.0", "keywords": ["..."] }
   ```
3. 커밋 → 푸시. 사용자는 `/plugin marketplace update` 후 새 스킬을 설치할 수 있습니다.

자세한 절차는 [`HOWTO-add-skill.md`](./HOWTO-add-skill.md) 참고.

## 구조

```
.claude-plugin/marketplace.json     # 전체 스킬 목록(플러그인 카탈로그)
plugins/
  travel-proposal/                  # ⚠ 레거시 레이아웃 (.claude/skills/ 중첩)
    .claude-plugin/plugin.json
    .claude/skills/travel-proposal/  SKILL.md + references/
    README.md
  higgsfield/                       # ✅ 표준 레이아웃 (skills/ 자동 탐색)
    .claude-plugin/plugin.json
    skills/higgsfield-{conti,estimate,generate,soul-id}/  SKILL.md + references/
    higgsfield.local.md.example      # 프로젝트별 예산·정책 주입 템플릿
    NOTICE                           # 제3자 콘텐츠 출처 고지 (generate는 MIT 아님)
    README.md
install.sh                          # 특정 스킬만 로컬 심링크(선택)
HOWTO-add-skill.md
LICENSE (MIT)
```

## 요구 사항

- Claude Code (플러그인/스킬 지원 버전)
- 스킬별 추가 요구사항은 각 `plugins/<name>/README.md` 참고
- macOS · Linux `bash` (Windows는 WSL 권장 — 심링크)

## 라이선스

MIT
