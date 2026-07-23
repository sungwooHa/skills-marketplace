---
name: dual-altitude-brief
description: Render one matter as a PAIR of pages — a high-altitude page (metaphor, concept, value; for executives, investors, non-specialist sponsors) and a low-altitude page (data model, interfaces, procedures, owners, done-criteria; for implementers) — bound together by shared item numbers, where an item without its pair counts as incomplete. Use when a decision, architecture, roadmap or program has to be both approved upstream and executed downstream, when a narrative owner and a spec owner must stay in sync, or when an executive deck and an engineering spec are drifting apart. Triggers — "경영진 보고랑 실행 스펙 같이", "승인용이랑 구현용 둘 다", "비유는 있는데 스펙이 없어", "보고서랑 설계서가 따로 논다", "dual altitude", "exec page and spec page", "pair the narrative with the spec". NOT for a single-audience document, and not a layout/rendering skill — page rendering belongs to slide-craft or deck-harness.
---

# dual-altitude-brief

One matter. Two pages. One numbering system.

A program that is described only in metaphor never gets built. A program that is described only
in specification never gets approved. Most organizations resolve this by producing two documents
at two different times, by two different people, that quietly stop agreeing with each other. This
skill removes that possibility by making the pair, not either page, the unit of delivery.

**Core rule: an item that exists on only one page is incomplete.** Not "to be detailed later" —
incomplete. It does not ship, and it is not reported as done.

## When this applies

Use it when all three hold:

- One matter (a decision, an architecture, a program, a roadmap phase) — not a document set.
- Two audiences with genuinely different vocabularies: one decides/funds, one builds.
- Someone will later ask "does the thing we built match the thing that was approved?"

Skip it for single-audience material, for a status update, or when the low-altitude content does
not exist yet — in that case the honest deliverable is the high-altitude page *plus an explicit
statement that no spec exists*, not a spec-shaped page filled with plausible invention.

## The two pages

| | High-altitude page | Low-altitude page |
|---|---|---|
| Reader | Executives, investors, sponsors, adjacent orgs | Implementers, reviewers, operators |
| Answers | Why this, why now, what changes if it works | What exactly is built, by whom, done when |
| Content | Metaphor, concept, value, before/after | Data model, interfaces, procedures, owners, done-criteria |
| Language | Everyday words; jargon only if defined on first use | Precise domain terms; no metaphor as a load-bearing element |
| Resolution test | "Would this line change someone's decision?" | "Could someone follow this and build the same thing?" |
| Owner | Narrative owner | Spec owner |

Both pages are derived from the same source of truth. Neither is a summary of the other — they
are two projections of one matter, and each is complete *for its reader*.

## Shared numbering (the binding mechanism)

Number the items once, on the matter itself, and use the same numbers on both pages.

- Every element of the metaphor has a spec counterpart carrying the same number.
- Every spec block has a place in the narrative carrying the same number.
- Numbers never get reused or renumbered per page. If the matter gains an item, both pages gain
  the number at the same time.
- Sub-items extend the number (`3`, `3.1`, `3.2`); they do not start a new sequence.

### Pair-completeness check (run before reporting done)

1. List the item numbers on the high-altitude page.
2. List the item numbers on the low-altitude page.
3. The two lists must be identical sets. Any number present on one side only is a defect.
4. For each number, verify the two entries describe the *same* item — a shared number over two
   different subjects is worse than a missing pair, because it looks complete.
5. Report unpaired numbers explicitly, as a list, rather than silently shipping the pair.

Cheap mechanical aid, when the pages are text files:

```bash
grep -oE '^\s*#?([0-9]+(\.[0-9]+)*)\b' high-altitude.md | tr -d ' #' | sort -u > /tmp/hi.txt
grep -oE '^\s*#?([0-9]+(\.[0-9]+)*)\b' low-altitude.md  | tr -d ' #' | sort -u > /tmp/lo.txt
diff /tmp/hi.txt /tmp/lo.txt && echo "pairs complete"
```

The diff is a hint, not the check — the check is step 4, and it needs judgment.

## Two owners, one numbering system

When the pages have different owners, the split is by page, never by item:

- The **narrative owner** writes the high-altitude page and does not invent spec content. Where a
  spec detail is needed, it is requested from the spec owner under its number.
- The **spec owner** writes the low-altitude page and does not decide the framing. Where framing
  is needed, it is requested from the narrative owner under its number.
- Neither owner may close an item alone: an item is closed when both entries exist and agree.
- If the two owners are two agents, they hand off through the orchestrator with the number as the
  handle. They do not open an autonomous debate — see `produce-verify-pair` for why round-tripping
  between agents is restricted to the one place it earns its cost.

## Anti-patterns

- **Never let a metaphor substitute for a spec.** "It works like a city's water system" is a
  reading aid, not an interface definition. If the metaphor is the only description of a
  mechanism, the item is unspecified.
- **Metaphor-only = execution failure. Spec-only = communication failure.** Both are failures of
  the same deliverable; neither page is the "real" one.
- **Do not invent a second metaphor.** Stay inside the sponsor's existing image system. A new
  metaphor forces readers to relearn the map and quietly changes what was approved.
- **Do not push the spec into the high-altitude page** to look rigorous. Detail removed from an
  executive page is *demoted to the paired page*, not deleted — that is what makes removal safe.
- **Do not treat "we'll write the spec after approval" as a pair.** That is the exact failure
  this skill exists to prevent: approval granted against content nobody could build from.
- **Do not render tentative items as settled** on either page. Provisional stays provisional at
  both altitudes, with the same qualifier.

## Worked example (generic — substitute your own domain)

> **Matter:** introducing a shared internal knowledge service that product teams query instead of
> maintaining private copies of the same reference data.
>
> **High-altitude page — "One library, many reading rooms"**
> 1. **One library.** Today every team keeps its own shelf; the same book exists in six editions
>    and nobody knows which is current. We move to one library.
> 2. **Reading rooms, not open stacks.** A team enters its own room and sees the books it is
>    entitled to — not the whole building.
> 3. **One door.** Everything comes in through the front desk, so nothing enters unrecorded.
> 4. **The librarian checks new books.** Nothing is shelved without being checked in.
>
> **Low-altitude page — service specification**
> 1. **Single store.** One primary datastore of record; team-local copies become read-through
>    caches. Owner: platform team. Done when no product service reads from a local copy.
> 2. **Tenant isolation.** Every record carries a tenant key; all reads are filtered by the
>    caller's tenant at the query layer, not in application code. Owner: platform team. Done when
>    a cross-tenant read attempt fails a test that asserts it is rejected.
> 3. **Single ingress.** One documented write endpoint; direct datastore writes are revoked at the
>    credential level. Owner: platform team. Done when no non-ingress write credential exists.
> 4. **Write validation.** Every write passes schema validation, referential checks, and a
>    duplicate check before commit; rejects are logged with a reason. Owner: data quality.
>    Done when the reject log shows all three rejection classes exercised by tests.
>
> Note the pairing: 1↔1, 2↔2, 3↔3, 4↔4. If the narrative later gains "5. Opening hours", the
> spec must gain a numbered availability item — or item 5 is incomplete and the pair does not ship.
> *(Everything above is illustrative filler; keep your own matter's numbers and content.)*

## Relationship to other skills

- **`ssot-doc-pipeline`** — both pages are artifacts derived from a manuscript. That skill owns
  where the source of truth lives and in what order edits happen; this skill owns what the pair
  must contain.
- **`produce-verify-pair`** — pair-completeness is a good thing to hand to an independent
  verifier, precisely because the author of a page is the worst judge of whether its counterpart
  says the same thing.
- **`slide-craft` / `generate-presentation`** — rendering. This skill is medium-agnostic: the pair
  may be two markdown files, two slides, or two sections of one document.
