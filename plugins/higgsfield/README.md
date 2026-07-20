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

## 게이트 강제 (PreToolUse 훅)

게이트는 문서상 규칙이 아니라 **실행 시점에 훅으로 강제**됩니다. 산문만으로는 `higgsfield generate create ...`를
Bash로 직접 실행하는 요청을 막지 못하므로, 이 플러그인은 `hooks/higgsfield-gate.js`(`PreToolUse` · matcher `Bash`)를
함께 설치합니다.

- **유료 호출** — `generate create`·`generate workflow`·`soul-id create`·`marketing-studio dtc-ads generate`·
  `marketing-studio ad-references create`·`product-photoshoot`·`marketplace-cards`. 유효한 승인 토큰이 없으면
  **차단**(exit 2)되고, 차단 사유가 에이전트에게 전달됩니다.
- **무료 호출** — `generate cost`·`list`·`get`·`wait`·`model`·`workflow`·`account status`·`auth`·`upload create`·
  `soul-id list|get|wait`·`marketing-studio ... list|get|fetch`·`--help`·`--cost-only`. 토큰 로직을 타기 **전에**
  통과 판정하므로, 토큰이 깨져 있어도 무료 호출은 막히지 않습니다.
- **Fail closed** — 파싱 실패·토큰 손상·판정 불가(미등록 `higgsfield` 하위명령)는 전부 차단. 돈이 나가는 경로에서는
  열어두지 않습니다.

### 승인 토큰

`higgsfield-estimate`가 **사용자가 승인 키워드(기본 `진행`)를 말한 순간에만** 프로젝트 루트에
`.claude/.higgsfield-gate-approval.json`을 씁니다.

```json
{
  "approved_at": "2026-07-20T09:12:00+09:00",
  "expires_at":  "2026-07-20T09:42:00+09:00",
  "runs_allowed": 3,
  "runs_used": 0,
  "estimated_credits": 216,
  "scope": "seedance_2_0"
}
```

훅은 ① 존재 ② 미만료(기본 30분) ③ `runs_used < runs_allowed` ④ 명령이 `scope`를 포함 — 네 조건을 모두 만족할 때만
통과시키고, 통과시키면서 `runs_used`를 증가시킵니다. 따라서 **승인 1회가 무제한 생성을 허가하지 못하며**, `runs_allowed`가
사실상 재생성 상한(`regen_cap_per_piece`)으로 동작합니다. 모델·작업이 바뀌면 `scope` 불일치로 차단되므로 재견적이 필요합니다.

이 파일은 **프로젝트별 런타임 상태**이며 커밋 대상이 아닙니다. 사용 프로젝트의 `.gitignore`에 추가하세요:

```gitignore
.claude/.higgsfield-gate-approval.json
```

### 이 훅이 막지 못하는 것 (한계)

**이 훅은 실수로 인한 지출을 막는 가드레일이지, 보안 경계가 아닙니다.** 아래는 알려진 한계이며, 감추지 않고 적습니다.

- **문자열만 봅니다.** 훅에 전달되는 것은 Bash 명령 문자열뿐입니다. 따라서 **의도적 우회는 통과합니다** —
  `HF=higgsfield; $HF generate create ...`(변수 간접), base64 디코드 실행, 래퍼 스크립트 경유 등.
  "산문 규칙이라 무시될 수 있음" → "우회하려면 작정해야 함" 수준으로 문턱을 올릴 뿐입니다.
- **승인 토큰은 에이전트가 쓸 수 있습니다.** 토큰은 `.claude/` 아래 평범한 파일이고, 에이전트가 사용자에게 묻는 대신
  스스로 써버리는 것을 **기계적으로 막는 장치는 없습니다.** 4개 스킬 모두 "직접 쓰지 말 것"을 명시하지만 그것은 다시
  산문입니다. 이 구멍을 실제로 닫으려면 토큰을 에이전트 통제 밖(사용자·외부 프로세스)에서 발급해야 합니다.
- **`node`가 PATH에 없으면 열립니다.** 훅 실행이 실패하면 종료코드가 2가 아니므로 Claude Code는 이를
  **비차단 오류**로 처리하고 명령을 그대로 실행합니다. Claude Code 자체가 Node를 동반하므로 현실성은 낮지만,
  남아 있는 유일한 fail-open 경로입니다. 다중 방어가 필요하면 **사용자 본인의** settings에 permission 규칙을
  추가하는 방법이 있습니다 (선택 사항 — 이 플러그인은 사용자 설정 파일을 건드리지 않습니다):
  ```json
  { "permissions": { "deny": ["Bash(higgsfield generate create:*)"] } }
  ```
- **회차는 실행 *전*에 차감됩니다.** 훅은 PreToolUse 시점에 `runs_used`를 올리므로, 제출이 실패한 생성도
  `runs_allowed` 한 회를 소모합니다. 안전한 방향의 오차이지만 오타 한 번으로 승인 회차를 잃을 수 있습니다.

### 회귀 테스트

`hooks/gate-test.sh`가 유료/무료 × 토큰 상태(없음·유효·소진·만료·손상) 조합을 훅에 직접 먹여 검증합니다.
**`higgsfield-gate.js`를 수정하면 반드시 함께 돌리고, 명령을 추가하면 같은 커밋에 케이스를 추가하세요.**

```bash
bash plugins/higgsfield/hooks/gate-test.sh   # 실패가 하나라도 있으면 비정상 종료
```

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
- **수정됨(2건).** ① 이 번들의 게이트 체인(conti G1 → estimate G3 → generate)을 강제하도록 패치하고 업스트림의
  "비용 사전 산정 생략" UX 규칙을 대체. ② 업스트림 `allowed-tools: Bash` 필드 삭제 — 파일 접근을 막아 같은 파일의
  "Load on demand: `references/…`" 지시 12건을 스스로 무력화하고 있었기 때문. 원본과 바이트 동일하지 않으며
  `version: 0.12.0+gated`로 표기합니다.
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
  hooks/
    hooks.json                       # PreToolUse(Bash) 등록
    higgsfield-gate.js               # 유료 호출 차단 · 승인 토큰 검증·소모
    gate-test.sh                     # 게이트 회귀 테스트 (훅 수정 시 필수 실행)
  skills/
    higgsfield-conti/SKILL.md
    higgsfield-estimate/SKILL.md
    higgsfield-estimate/references/price-table.md
    higgsfield-generate/SKILL.md + references/ (12종)
    higgsfield-soul-id/SKILL.md
```
