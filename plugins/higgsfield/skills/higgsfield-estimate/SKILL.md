---
name: higgsfield-estimate
description: |
  Mandatory estimate gate before paid Higgsfield generation. Before every generate call (including image·video·콘티),
  present model·settings·run count·expected credits·budget comparison as a table and get explicit "진행" (proceed) approval.
  After generation, record actual spend and update the price table. Triggers — "견적", "비용 산정", "크레딧 얼마",
  or when Higgsfield generation is requested without estimate approval (route through this skill first). No generation without an estimate.
argument-hint: "[asset-list or model + settings] [--runs <n>]"
allowed-tools: Bash
version: 1.0.0
---

# Higgsfield Estimate Gate (G3)

**No paid generation without an estimate — no exceptions (including automatic mode).** Silent credit burn is the
#1 trust-breaking incident. This gate takes precedence over the official skill's (higgsfield-generate) "skip cost pre-estimation"
UX rule — within this bundle, the spending discipline wins over that UX preference.

## Step 0 — Read project config

At gate entry, read `.claude/higgsfield.local.md` from the project root if it exists. Parse simple `key: value` lines
(ignore blank lines, `#` comments, and markdown prose). Keys used by this skill:

| Key | Default if missing |
|---|---|
| `event_name` | none — omit project attribution from the estimate table |
| `budget_cap_credits` | none — **ask the user for the budget cap** before presenting the estimate |
| `regen_cap_per_piece` | `3` |
| `spend_ledger_path` | none — **warn** that spend will not be recorded, then skip the recording step |
| `escalation_role` | `the user` |
| `approval_keyword` | `진행` |

## Procedure

1. **Confirm the asset list** — what is generated and how many times (including regeneration budget)
2. **Look up unit prices** — ① try `higgsfield generate cost <job_set_type> <플래그들>` (CLI actual unit price; for workflows,
   `generate cost workflow <name>`) — this is authoritative ② on failure, fall back to `references/price-table.md`
3. **Present the estimate table**:
   | 애셋 | 모델·설정 | 회차 | 크레딧 |
   total + comparison against `budget_cap_credits` (if `event_name` is set, label the budget line with it) + if possible,
   account balance·balance after deduction
4. **Wait for explicit approval** — execute generation only after the user's `approval_keyword` (default "진행")
5. **Record actual spend** — on completion, record the measured credits at `spend_ledger_path`; if `spend_ledger_path` is not
   configured, warn the user that the spend is unrecorded and skip. If the measurement differs from `references/price-table.md`,
   proceed with the real number and file the correction as a marketplace PR (see that file's correction policy)

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
