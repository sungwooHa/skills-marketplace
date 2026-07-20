# higgsfield

[![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-D97757?logo=anthropic&logoColor=white)](https://github.com/sungwooHa/skills-marketplace)
[![version](https://img.shields.io/badge/version-1.0.0-informational)](./.claude-plugin/plugin.json)
[![skills](https://img.shields.io/badge/skills-4%20bundled-4C9A2A)](#수록-스킬-4종-함께-설치)
[![gates](https://img.shields.io/badge/gates-conti%20%E2%86%92%20estimate%20%E2%86%92%20generate-ff6b35)](#게이트-체인)
[![license](https://img.shields.io/badge/license-MIT%20(generate%20%EC%A0%9C%EC%99%B8)-blue)](./NOTICE)

Higgsfield AI로 영상·이미지·3D·오디오를 생성하는 **4스킬 번들**. 돈이 나가는 지점마다 승인 게이트를 세워
"조용한 크레딧 소진"을 막는 것이 이 번들의 존재 이유입니다.

## 수록 스킬 (4종 함께 설치)

이 플러그인은 **4개 스킬을 함께 설치**합니다. 게이트가 서로를 호출하기 때문에 개별 설치를 지원하지 않습니다.

| 스킬 | 역할 | 과금 |
|---|---|---|
| **higgsfield-conti** | G1 — 콘티(스토리보드) 게이트. 6컷 진행 콘티를 만들어 승인받고, 확정 콘티를 영상 프롬프트 타임라인으로 전사 | 콘티 이미지 생성분 |
| **higgsfield-estimate** | G3 — 견적 게이트. 모델·설정·회차·예상 크레딧을 표로 제시하고 명시적 승인을 받음 | 무료 |
| **higgsfield-generate** | 생성 엔진. 이미지·영상·3D·오디오·Marketing Studio·Virality Predictor | 유료 |
| **higgsfield-soul-id** | Soul 캐릭터 레퍼런스 학습·관리. 얼굴·정체성 일관성용 `<soul_ref_id>`를 생성해 generate가 소비 | `create`만 유료 |

## 게이트 체인

```
higgsfield-conti (G1)  →  higgsfield-estimate (G3)  →  higgsfield-generate
   콘티 승인                    견적 승인                    실제 생성

higgsfield-soul-id  →  (estimate 게이트 경유)  →  <soul_ref_id>  →  generate가 소비
```

- **무콘티 생성 금지** — 영상 생성 요청이 콘티 승인 없이 오면 conti로 먼저 라우팅.
- **무견적 생성 금지** — 콘티 이미지를 포함한 모든 유료 호출은 estimate 승인 후에만 실행.
- **무견적 학습 금지** — `soul-id create`도 유료이므로 estimate 게이트를 통과해야 함.
- estimate 게이트는 generate의 "비용 사전 산정 생략" UX 규칙보다 **우선**합니다 (번들 차원의 지출 규율).
  이 우선순위는 문서상 선언이 아니라 `higgsfield-generate/SKILL.md`에 직접 패치되어 있습니다 — 해당 UX 규칙을
  대체하고, 파일 상단에 게이트 체인 절을 두어 generate 단독 발동 시에도 게이트로 라우팅됩니다.
- 무료 호출(`generate cost`·`list`·`get`·`model list` 등)은 게이트 면제.

## 설치

```
/plugin marketplace add sungwooHa/skills-marketplace
/plugin install higgsfield@skills-marketplace
```

- 업데이트: `/plugin marketplace update skills-marketplace`
- 제거: `/plugin uninstall higgsfield`

## 사전 요구사항

1. **`higgsfield` CLI 설치**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/higgsfield-ai/cli/main/install.sh | sh
   ```
2. **인증** — `higgsfield auth login` (대화형). `higgsfield account status`로 확인.
3. 크레딧 잔액 — 유료 모델은 플랜 게이팅이 걸릴 수 있습니다 (Starter 플랜에서 `seedance_2_0` 등 차단).

## 프로젝트별 설정 (`.claude/higgsfield.local.md`)

예산·정책은 스킬에 하드코딩하지 않고 **프로젝트마다 주입**합니다.
[`higgsfield.local.md.example`](./higgsfield.local.md.example)을 프로젝트 루트의 `.claude/higgsfield.local.md`로 복사해 채우세요.

게이트 진입 시 이 파일을 읽고, `key: value` 라인을 파싱하며, 없는 키는 기본값을 적용합니다. 파일이 없으면 전부 기본값입니다.

| 키 | 기본값 (미지정 시 동작) |
|---|---|
| `event_name` | 없음 — 견적표에서 프로젝트 귀속 표기 생략 |
| `budget_cap_credits` | 없음 — **사용자에게 예산 상한을 물음** |
| `regen_cap_per_piece` | `3` |
| `style_source` | 없음 — 스타일락 상속을 건너뛰고 **팔레트·무드·네거티브를 물음** |
| `spend_ledger_path` | 없음 — **미기록 경고 후 기록 단계 건너뜀** |
| `escalation_role` | `the user` |
| `approval_keyword` | `진행` |

최소 예시:

```
budget_cap_credits: 500
escalation_role: 프로젝트 리드
```

## 단가표 수정 정책

단가는 `higgsfield generate cost <job_set_type>` **라이브 조회가 정본**입니다.
CLI 조회 실패 시에만 [`skills/higgsfield-estimate/references/price-table.md`](./skills/higgsfield-estimate/references/price-table.md)로 폴백합니다.

측정값이 표와 다르면:

1. 눈앞의 실행은 실측값으로 진행.
2. 정정은 **마켓플레이스 레포에 PR**로 반영 (새 값 · 측정 설정 · 측정일 명시).
3. **프로젝트 안에서 이 파일을 고치지 마세요** — 플러그인 업데이트 때 덮어써지고, 다른 프로젝트에 정정이 전파되지 않습니다.

## 출처·라이선스 (higgsfield-generate)

**`higgsfield-generate`는 이 레포가 작성한 스킬이 아닙니다.** Higgsfield가 배포한 `.skill` 번들
(스킬명 `higgsfield-generate`, 업스트림 `version: 0.12.0`)에서 가져온 제3자 콘텐츠입니다.

- **업스트림 라이선스: 미상.** 배포 번들에 라이선스 파일·허락 문구가 없었습니다. 이 레포는 해당 파일에 대해
  어떤 라이선스도 주장하지 않으며, 재배포 권한을 보유한다고 주장하지 않습니다. **재배포 권한은 미해결 상태입니다.**
- **수정됨.** 이 번들의 게이트 체인(conti G1 → estimate G3 → generate)을 강제하도록 패치했고,
  업스트림의 "비용 사전 산정 생략" UX 규칙을 대체했습니다. 원본과 바이트 동일하지 않으며 `version: 0.12.0+gated`로 표기합니다.
- 루트 MIT 라이선스는 이 파일에 **적용되지 않습니다**. 나머지 3개 스킬(conti·estimate·soul-id)은 이 레포 저작물로 MIT입니다.
- 상세: [`NOTICE`](./NOTICE). "Higgsfield" 명칭·상표는 권리자 소유이며, 여기서의 사용은 CLI·서비스를 지칭하는
  기술적 표현으로 제휴·보증을 의미하지 않습니다.

## 구성

```
plugins/higgsfield/
  .claude-plugin/plugin.json
  README.md
  NOTICE                             # 제3자 콘텐츠 출처 고지 (higgsfield-generate)
  higgsfield.local.md.example
  skills/
    higgsfield-conti/SKILL.md
    higgsfield-estimate/SKILL.md
    higgsfield-estimate/references/price-table.md
    higgsfield-generate/SKILL.md + references/ (12종)
    higgsfield-soul-id/SKILL.md
```
