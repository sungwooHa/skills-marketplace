---
name: higgsfield-estimate
description: |
  Mandatory estimate gate before paid Higgsfield generation. Before every generate call (including image·video·콘티),
  present model·settings·run count·expected credits·budget comparison as a table and get explicit "진행" (proceed) approval.
  After generation, record the actual spend to the project's spend ledger; if it differs from the bundled price table,
  proceed with the real number and file the correction as a marketplace PR (never edit the shipped table in-project).
  Triggers — "견적", "비용 산정", "크레딧 얼마",
  or when Higgsfield generation is requested without estimate approval (route through this skill first). No generation without an estimate.
argument-hint: "[asset-list or model + settings] [--runs <n>]"
version: 1.0.0
---

# Higgsfield Estimate Gate (G3)

**No paid generation without an estimate — no exceptions (including automatic mode).** Silent credit burn is the
#1 trust-breaking incident. This gate takes precedence over the official skill's (higgsfield-generate) "skip cost pre-estimation"
UX rule — within this bundle, the spending discipline wins over that UX preference.

## Step 0 — Read project config (canonical spec for the whole bundle)

**This section is the single source of truth for `.claude/higgsfield.local.md` parsing.** `higgsfield-conti` and
`higgsfield-soul-id` reference it rather than restating it; keep the spec here only.

At gate entry, read `.claude/higgsfield.local.md` from the project root if it exists. Parse simple `key: value` lines
(ignore blank lines, `#` comments, and markdown prose).

| Key | Used by | Default if missing |
|---|---|---|
| `event_name` | estimate | none — omit project attribution from the estimate table |
| `budget_cap_credits` | estimate | none — **ask the user for the budget cap** before presenting the estimate. Never assume a cap |
| `regen_cap_per_piece` | estimate | `3` |
| `spend_ledger_path` | estimate | none — **warn** that spend will not be recorded, then skip the recording step |
| `style_source` | conti | none — skip style-lock inheritance and ask the user for palette·mood·negatives |
| `escalation_role` | all | `the user` |
| `approval_keyword` | all | `진행` |

Missing file = all defaults. Do not invent values, and do not block on the config — every key has a defined fallback, and the
one money-critical key (`budget_cap_credits`) falls back to **asking the user**, never to an assumed number.

## Procedure

1. **Confirm the asset list** — what is generated and how many times (including regeneration budget)
2. **Look up unit prices** — ① try `higgsfield generate cost <job_set_type> <플래그들>` (CLI actual unit price; for workflows,
   `generate cost workflow <name>`) — this is authoritative ② on failure, fall back to `references/price-table.md`
3. **Present the estimate table**:
   | 애셋 | 모델·설정 | 회차 | 크레딧 |
   total + comparison against `budget_cap_credits` (if `event_name` is set, label the budget line with it) + if possible,
   account balance·balance after deduction
4. **Wait for explicit approval** — execute generation only after the user's `approval_keyword` (default "진행")
5. **Write the approval token** — the moment the user gives the keyword, and only then (see "Approval token" below).
   Without it the plugin's PreToolUse hook blocks every paid call
6. **Record actual spend** — on completion, record the measured credits at `spend_ledger_path`; if `spend_ledger_path` is not
   configured, warn the user that the spend is unrecorded and skip. If the measurement differs from `references/price-table.md`,
   proceed with the real number and file the correction as a marketplace PR (see that file's correction policy)

## Approval token (what makes the gate binding)

This gate is enforced at execution time by the plugin's `PreToolUse` hook (`hooks/higgsfield-gate.js`), which blocks every
paid `higgsfield` call unless a valid approval token is on disk. Prose alone does not stop a direct Bash call; the token does.

**Write the token only after the user says the `approval_keyword`.** Never pre-write it, never write it on the user's behalf,
and never widen it to cover work the estimate table did not present.

Path: `.claude/.higgsfield-gate-approval.json` in the **project root** (create `.claude/` if missing).

```json
{
  "approved_at": "2026-07-20T09:12:00+09:00",
  "expires_at": "2026-07-20T09:42:00+09:00",
  "runs_allowed": 3,
  "runs_used": 0,
  "estimated_credits": 216,
  "scope": "seedance_2_0"
}
```

| Field | Rule |
|---|---|
| `approved_at` | ISO8601, the moment the keyword was given |
| `expires_at` | ISO8601, **default `approved_at` + 30 minutes**. An expired approval is not an approval — re-estimate |
| `runs_allowed` | Integer. Exactly the run count the estimate table presented and the user approved — nothing rounded up |
| `runs_used` | Starts at `0`. The hook increments it on every allowed paid call; do not edit it afterwards |
| `estimated_credits` | The total from the estimate table (record only; the hook does not enforce it) |
| `scope` | Substring the approved command must contain — normally the `job_set_type` (`seedance_2_0`), the workflow name, or the subcommand (`soul-id create`, `dtc-ads generate`). `"*"` means any paid call and should be avoided |

The hook consumes one run per paid command, so `runs_allowed` is also the regeneration cap (`regen_cap_per_piece`) in practice:
once it is spent, generation stops until a fresh estimate is approved. A different model or job type needs a new token —
a `scope` mismatch blocks.

The token is per-project runtime state. It is **never committed** — add `.claude/.higgsfield-gate-approval.json` to the
project's `.gitignore`.

## Price lookup

Unit prices are read live via `higgsfield generate cost`; fall back to `references/price-table.md` when the CLI lookup fails.
Corrections go via a marketplace PR to that file, never edited in-project.

## Pitfalls (preventing spending incidents)

1. **seedance_1_5 duration trap** — when `duration` is unspecified, it defaults to 12s (3× the cost of 4s) → **always specify**
2. **Plan gating** — higher-tier models (seedance_2_0, etc.) are blocked on the Starter plan and the error is only
   "Something went wrong" → on a mystery model error, suspect the plan before debugging the prompt
3. **Top-up pack expires in 90 days** — don't stockpile credits; buy at the point of need
4. **Regeneration cap** — `regen_cap_per_piece` runs per piece (default 3); on exceeding, stop·escalate to the `escalation_role`
5. **Content-policy blocks** — don't retry the same input with the same model (it only burns credits); propose changing the input or the model
