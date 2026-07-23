# report-set — several report pages that ship as one document

**Use when** the argument needs more than one page and the pages are *read*, not *presented*.
This archetype is a container: each page inside it picks one of the single-page archetypes.

**Not for talks.** If a presenter will stand up and walk an audience through this, with speaker
notes and a slide-at-a-time reveal, that is the `generate-presentation` skill in the deck-harness
plugin — it owns planning, building and the 5-axis critic panel for talk decks. Do not build a
presenter viewer here. The two are distinguishable by a single question: *does the reader control
the pace?* If yes, report-set. If a presenter does, deck-harness.

**Page economy** — N pages, **one message per page**, ≤5 visual groups per page. The set should
be summarizable as N sentences, one per page. Two pages yielding the same sentence should merge;
one page needing two sentences should split.

**Reading order** — page 1 → N, and the reader treats the set as *one document* — flipping back,
comparing page 2 against page 5. That random access is exactly what a talk deck does not have,
and it is why the cross-page contract below is the real work of this archetype.

## Cross-page contract

1. **One file per page**, named by order and topic: `01-summary.html`, `02-architecture.html`.
   Never version individual pages — **version the set as a folder**. Any single-page edit bumps
   the whole set. Individually versioned pages (`03-roadmap_v4.html`) are how a set silently
   desynchronizes.
2. **Top-level title hierarchy is one system.** If body pages use a 44px page title, the cover
   page's top-level identifier is also 44px. A 16px cover label against 44px body titles reads as
   a different document that got stapled on.
3. **Shared token block.** Every page imports the identical `:root` block from the theme. When
   transplanting a block from a verified page into a new one, snap font sizes, weights, paddings
   and gaps against the verified original and re-check by cropping the PNG. Silent drift during
   transplant is the most-repeated defect in multi-page work.
4. **Phrase echo.** When one page fixes a phrase for a concept, later pages reuse *that* phrase or
   a direct inflection of it, not a fresh paraphrase. Different wording reads as a different
   claim. Echo only where needed — repeating it on every page is its own failure.
5. **No page narrates the set.** No "how to read this", no visible Q1–Q4 scaffold, no "evidence
   follows on page 4". Order and layout carry that.
6. **Page numbers and a set identifier on every page** (`Report name · 3 / 7`). A page that
   escapes the folder must still announce what it belongs to.

## Shipping the set

The deliverable is **one PDF**, not a folder of HTML files. Print each page at the same page size
and concatenate, or build a single HTML file with one `.page` per sheet and a page break between:

```css
@page{size:420mm 297mm;margin:0}          /* A3 landscape — match theme page.print */
@media print{
  body{background:#fff;padding:0;margin:0}
  .page{break-after:page;display:grid;place-items:center;height:296mm;overflow:hidden}
  .page:last-child{break-after:auto}
  .slide{box-shadow:none;border-radius:0;zoom:.97}
}
@media screen{ .page{margin:0 auto 28px} }
```

A screen reader of the set gets a plain vertical scroll — no viewer JavaScript, no keyboard
handler, no fullscreen mode. Keeping this archetype JS-free is deliberate: it is what keeps
report-set from drifting into a second-rate copy of deck-harness's presenter deck.

## Verification

Run `slide_qa.py` **per page**, then once on the combined print file:

```bash
for f in set/*.html; do
  python3 scripts/slide_qa.py "$f" --out /tmp/set-qa || echo "FAIL $f"
done
python3 scripts/slide_qa.py set/_all.html --out /tmp/set-qa \
        --pdf --page-size A3-landscape --expect-pages 7
```

One page failing fails the set. The `--expect-pages` check is the one that catches a missing
`@page` rule — without it a 7-page set silently becomes 14 letter-portrait pages.

## Archetype-specific failure modes

- Individually versioned pages instead of a versioned folder.
- Cover page at a different title scale from body pages.
- The same concept described three different ways across three pages.
- Fonts or margins drifting after a block was copied between pages.
- Shipping a folder of HTML files and calling it the deliverable.
- Producing PDFs on every revision round while content is still churning — stay HTML+PNG until
  the content settles, then do one final print pass.
- Building a presenter/fullscreen mode here. That is deck-harness's job; if it is wanted, the
  request was for a talk deck all along.
