---
name: higgsfield-soul-id
description: |
  Train and manage Higgsfield Soul Character references for face/identity consistency across generations.
  Wraps the `higgsfield soul-id` command group: train a Soul 2.0 or Soul Cinematic reference from 5–20 images,
  poll training to completion, list and inspect existing references, and hand the resulting reference id to
  higgsfield-generate. Triggers — "소울 학습", "캐릭터 학습시켜줘", "얼굴 일관성", "soul id 만들어",
  "same character across images", or when a generation request needs a consistent identity and no Soul reference exists yet.
  Training is PAID — no training without an estimate (무견적 학습 금지); route through higgsfield-estimate first.
  NOT for: generating with an existing Soul reference (use higgsfield-generate), Marketing Studio avatars.
argument-hint: "[character-name] [--image <path>...] [--soul-2|--soul-cinematic]"
allowed-tools: Bash
version: 1.0.0
---

# Higgsfield Soul ID

Trains and manages **Soul Character references** — the identity anchor that keeps the same face across many generations.

This skill is the **producer**; `higgsfield-generate` is the **consumer**. This skill emits a `<soul_ref_id>`; generate spends it.

## Gate — training is paid

`soul-id create` spends credits. **No training without an estimate (무견적 학습 금지.)**

Before running `create`, route through `higgsfield-estimate` exactly as `higgsfield-conti` does: present model
(`--soul-2` vs `--soul-cinematic`), image count, run count, and expected credits, and wait for the configured
approval keyword (default "진행"). `list`, `get`, and `wait` are free — no gate needed for those.

At gate entry, read `.claude/higgsfield.local.md` from the project root if present (see `higgsfield-estimate` Step 0 for the
key table); this skill uses `approval_keyword` and `escalation_role`.

## Step 0 — Bootstrap

1. If `higgsfield` is not on `$PATH`, install it:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/higgsfield-ai/cli/main/install.sh | sh
   ```
2. If `higgsfield account status` fails with `Session expired` / `Not authenticated`, ask the user to run
   `higgsfield auth login` (interactive) and wait for confirmation.

## Workflow — train a new Soul reference

1. **Check what already exists first.** Training is paid; a usable reference may already be there.
   ```bash
   higgsfield soul-id list --json
   higgsfield soul-id list --soul-2          # filter to Soul 2.0 refs
   higgsfield soul-id list --soul-cinematic  # filter to Soul Cinematic refs
   higgsfield soul-id list --size 50         # page size, default 20
   ```

2. **Pick the model tier.** Exactly one of:
   - `--soul-2` — Soul 2.0. Default for stills, UGC, fashion/editorial, lifestyle character work.
   - `--soul-cinematic` — Soul Cinematic. For cinematic frames and film-look output.

3. **Collect images.** `--image` is repeatable and takes **either a local file path or an upload UUID**.
   The CLI accepts **5–20 images**. Fewer than 5 is rejected — gather more before spending.
   Prefer varied angles and lighting of the same identity; near-duplicate frames waste the training budget.

4. **Estimate, then train.** After the estimate gate passes:
   ```bash
   higgsfield soul-id create --name Alice --soul-2 \
     --image ./alice1.png --image ./alice2.jpg --image ./alice3.png \
     --image ./alice4.jpg --image ./alice5.png
   ```
   Mixed sources are fine:
   ```bash
   higgsfield soul-id create --name Alice --soul-cinematic --image <upload_id> --image ./alice2.jpg
   ```
   `--name` is required. The command returns a `<soul_id>`.

5. **Wait for training.** Training is asynchronous:
   ```bash
   higgsfield soul-id wait <soul_id>
   higgsfield soul-id wait <soul_id> --timeout 45m --interval 15s   # defaults: 30m / 10s
   higgsfield soul-id wait <soul_id> --quiet                        # no progress output
   ```
   If training exceeds the timeout, re-issue `wait` — it rejoins the same job rather than retraining.
   Repeated failures on the same input: stop and escalate to the `escalation_role` instead of retrying (each retrain is paid).

6. **Inspect and hand off.**
   ```bash
   higgsfield soul-id get <soul_id> --json
   ```
   Report the reference id and a one-line summary (name, tier, status). Don't dump raw JSON into chat.

## Producer/consumer contract

The trained reference id is consumed by `higgsfield-generate`:

```bash
higgsfield generate create text2image_soul_v2 --prompt "..." --soul-id <soul_ref_id> --quality 2k --wait
higgsfield generate create soul_cinematic     --prompt "..." --soul-id <soul_ref_id> --quality 2k --wait
```

- Match the tier: a `--soul-2` reference goes to `text2image_soul_v2`; a `--soul-cinematic` reference goes to `soul_cinematic`.
- Soul image quality is `--quality 1.5k` or `--quality 2k` (UI-facing tiers; the backend maps them to `720p`/`1080p`).
- Generation with an existing reference is `higgsfield-generate`'s job, not this skill's — hand over the id and stop.

## Rules (summary)

- **무견적 학습 금지** — `create` never runs before the `higgsfield-estimate` gate approves it.
- Always `list` before `create` — reuse beats retraining.
- 5–20 images, one tier flag, `--name` required.
- `list` / `get` / `wait` are free and safe; `create` is the only spending command in this skill.
- On repeated training failure, escalate rather than retry — retries are billed.

## Errors

- `Session expired` → `higgsfield auth login`.
- Fewer than 5 `--image` values → collect more images; the CLI rejects the call.
- Both `--soul-2` and `--soul-cinematic` passed → pick exactly one tier.
- `--soul-id` rejected by a generate model → tier mismatch; check `get <soul_id>` and route to the matching model.

## Global flags

`--json` prints raw JSON responses (use for chaining, not for chat output). `--no-color` disables color output.
