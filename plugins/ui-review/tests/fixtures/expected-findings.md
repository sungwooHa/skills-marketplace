# PlantedViolations.kt — answer key

For LLM-based regression verification: run each skill against `PlantedViolations.kt`
(a reviewer agent must NOT read this file) and compare its findings to this key.
Pass bar: every "must-catch" found, no fabricated project-specific rules.

## design-review (Noa) must catch

| Line area | Planted violation | Check |
|---|---|---|
| `padding(10.dp)` | off the 8px grid | C |
| screen subtitle "할 일 목록을 관리하는… + 버튼을 눌러 추가하세요" | redundant coaching copy (button narration + operation instruction) | L |
| `fontSize = 11.sp` (subtitle and "tail" label) | below 12sp caption floor | D |
| `Text("tail", …)` | debug placeholder leaked to user-facing string | M (Critical) |
| delete `Icon … size(20.dp).clickable` | interactive element below 44dp floor | B (Critical) |
| empty state second line "…+ 버튼을 누르면 만들 수 있어요" | empty-state coaching (keep status line only) | L |

Should NOT be flagged by Noa: tween/scaleIn/easing/scale — those are Rei's axis (one-line handoff at most).

## motion-review (Rei) must catch

| Line area | Planted violation | Check |
|---|---|---|
| `tween(durationMillis = 400, …)` | exceeds 300ms interactive ceiling | M-D |
| `easing = FastOutLinearInEasing` on press-feedback response | accelerate easing on interactive response | M-C (Critical) |
| `enter = scaleIn() + fadeIn()` | bare scaleIn() → default initialScale 0f | M-E (Critical) |
| `Modifier.scale(pressScale)` | per-frame animated value read in composition (should be graphicsLayer lambda) | M-G |
| `indication = null` with no replacement feedback | dead tap — absent response | M-A |
| press feedback animated with 400ms tween | press-down must be immediate; symmetric/slow press timing | M-I |

Should NOT be flagged by Rei: 10.dp padding, 11.sp fonts, "tail" string — Noa's axis.
Also acceptable: frequency-tier reasoning that a task-list toggle is a high/tens-per-day surface.
