# Spec schema

The spec is a single JSON object. The generator reads it and stamps out the project. **Same spec + same
templates = byte-identical tree.** Keep the key order below — the generator re-emits the frozen spec in
exactly this order for determinism.

## Fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `chassisVersion` | integer | yes | Current canon version the core was stamped from. Bumped on re-sync. |
| `mission` | string | yes | One–two sentences: the outcome. Becomes the `## 미션` line. |
| `workType` | enum | yes | One of `코드` \| `문서·글` \| `리서치·분석` \| `운영·조율` \| `혼합`. |
| `responseStyle` | string | yes | Output language/style. Default `개조식 한국어`. |
| `gates` | string[] | yes | Irreversible/outward actions gated by `advisor` go/no-go. May be empty. |
| `agents` | object[] | yes | Seed agents. Each: `{name, role, triggers, focus}` (in this key order). |

### `agents[]` object

| Field | Type | Notes |
|---|---|---|
| `name` | string | PROJECT-DOMAIN Korean noun (e.g. `코드리뷰어`). Never a generic role word. Becomes the display name; the generator derives a filesystem-safe slug for the frontmatter `name` and filename. |
| `role` | enum | `execute` \| `review` \| `research`. Selects the template skeleton (execute→executor, review→reviewer, research→researcher). |
| `triggers` | string[] | 2–4 short phrases that route to this agent. Rendered into the routing index and the agent's description. |
| `focus` | string | One sentence: what this agent owns in THIS project. The tailoring lives here. |

## Complete example

```json
{
  "chassisVersion": 1,
  "mission": "사내 결제 서비스의 백엔드 API를 설계·구현·검증한다.",
  "workType": "코드",
  "responseStyle": "개조식 한국어",
  "gates": ["배포"],
  "agents": [
    {
      "name": "코드리뷰어",
      "role": "review",
      "triggers": ["코드 리뷰", "PR 점검", "머지 전 검토"],
      "focus": "결제 로직의 정합성·동시성·롤백 안전성을 비실행 판정으로만 검토하고, 산출물을 고치지 않고 결함 리포트만 낸다."
    },
    {
      "name": "스펙조사가",
      "role": "research",
      "triggers": ["결제 표준 조사", "PG 연동 레퍼런스", "규제 확인"],
      "focus": "PG사 API·카드망 규격·전자금융 규제 등 외부 레퍼런스를 근거와 함께 조사·요약한다."
    },
    {
      "name": "백엔드실행가",
      "role": "execute",
      "triggers": ["API 구현", "스키마 마이그레이션", "대량 편집"],
      "focus": "확정된 스펙을 받아 다파일 구현·마이그레이션·리팩토링을 수술적으로 수행한다."
    }
  ]
}
```

## Token substitution (generator)

The generator substitutes these into `core.template.md` (the CANON block and the operating-discipline
block are copied BYTE-EXACT — only tokens change):

| Token | Source |
|---|---|
| `{{MISSION}}` | `spec.mission` |
| `{{RESPONSE_STYLE}}` | `spec.responseStyle` |
| `{{CHASSIS_VERSION}}` | `spec.chassisVersion` |
| `{{ROUTING_INDEX}}` | one line per `spec.agents`: `「<name>」 — <triggers joined>` |
| `{{GATES}}` | one `- <gate>` bullet per `spec.gates` (or a `없음` placeholder if empty) |

Agent templates substitute `{{AGENT_SLUG}}` (frontmatter name/filename), `{{AGENT_NAME}}` (Korean display
name), `{{TRIGGERS}}`, `{{FOCUS}}`.
