# Measured price table (fallback only)

**This table is a fallback, not the source of truth.** The authoritative unit price is always the live CLI lookup:

```bash
higgsfield generate cost <job_set_type> <flags>
higgsfield generate cost workflow <workflow_name> <flags>
```

Use this table only when the CLI lookup fails (offline, auth expired, unknown job_set_type).

**Verification dates are per row.** There is no single "last verified" date for this table — rows were measured at
different times, and some carry no recorded date at all. Treat an undated row as the weakest confidence tier: get a live
`generate cost` before letting it drive a spending decision.

| Model | Settings | Credits | Method | Verified |
|---|---|---|---|---|
| `seedance_2_0` | std · 1080p · 8s · no audio | **72** | external guide, measured | 2026-07-07 |
| `seedance_2_0` | 4K · 8s | 176 | external guide, measured | undated |
| `nano_banana_2` | 2K | ~11 | external guide, measured | undated |
| `gpt_image_2` | 2K · 16:9 | **7** | CLI `generate cost`, measured | 2026-07-14 |
| `seedance_1_5` | 480p · 4s / 12s | 2.4 / 7.2 | external guide, measured | undated |
| Generic image | 2K~4K | 1–15 | external guide, measured range | undated |

## Correction policy

Unit prices drift. When a measured actual differs from this table:

1. Trust the CLI / dashboard actual for the run in front of you — proceed with the real number.
2. Submit the correction as a **pull request to this file in the marketplace repo**, with the new value, the settings it was
   measured under, and the measurement date — fill that date into the row's `Verified` column. Never stamp a date on a row
   you did not measure.
3. **Never edit this file inside a consuming project.** It ships with the plugin; in-project edits are overwritten on the next
   plugin update and the correction is lost to every other project.

Rows whose price cannot be reproduced by a CLI lookup should be marked `external guide, measured` so a reader knows the
confidence level differs from a CLI-verified row.
