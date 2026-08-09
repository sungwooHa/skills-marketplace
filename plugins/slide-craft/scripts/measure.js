/* slide-craft — headless measurement pass for slide-clinic.
 *
 *   node measure.js slide.html [more.html ...]
 *
 * Renders each slide at 1280x720 and prints ONE JSON object per file with the
 * facts the design grammar judges on. It measures; it does not judge and does
 * not edit. Verdicts belong to slide-clinic / design-diagnostician.
 *
 * Requires playwright in the working directory or globally:
 *   npm i playwright && npx playwright install chromium
 */
const { chromium } = require('playwright');
const path = require('path');

const SCALE = [17, 19, 19.6, 21.3, 22.4, 22.5, 25, 26.3, 29, 44]; // design-grammar §0-2
const PALETTE = [
  '#f6f7f9', '#ffffff', '#000000', '#1a1a1a', '#111113', '#2b5fe0', '#2b64f1',
  '#8a8b8f', '#3a3a3c', '#a0a0a4', '#aeaeb2', '#b4b4b8', '#b3b3b6', '#c9c9cd',
  '#efeff1', '#f0f0f2', '#a1a2a6', '#e6e6e8', '#bfbfc2', '#8a8a8e', '#8e8e92',
];

(async () => {
  const files = process.argv.slice(2);
  if (!files.length) { console.error('usage: node measure.js <slide.html> ...'); process.exit(1); }

  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 }, deviceScaleFactor: 1 });

  for (const f of files) {
    const abs = path.resolve(f);
    await page.goto('file://' + abs);
    await page.waitForTimeout(200);

    const data = await page.evaluate(({ SCALE, PALETTE }) => {
      const slide = document.querySelector('.slide');
      if (!slide) return { error: 'no .slide element' };
      const sr = slide.getBoundingClientRect();

      const rgbToHex = (c) => {
        const m = c && c.match(/\d+/g);
        if (!m || m.length < 3) return null;
        if (m.length > 3 && Number(m[3]) === 0) return null; // fully transparent
        return '#' + m.slice(0, 3).map(n => Number(n).toString(16).padStart(2, '0')).join('');
      };

      const all = [...slide.querySelectorAll('*')];

      // Decoration carries a font-size but is not type: icon glyphs, arrow marks,
      // the meta tick, image placeholder labels. Counting them poisons the type
      // scale and the emphasis ratio, so they are excluded from all text analysis.
      const DECOR = ['icon', 'ar', 'bar', 'hl', 'photo', 'kard-photo', 'slot', 'guides'];
      const isDecor = (el) =>
        DECOR.some(c => el.classList.contains(c)) ||
        ['SUP', 'SUB'].includes(el.tagName) ||        // 40m² — typographic, not a type step
        !/[가-힣A-Za-z0-9]/.test(el.textContent);     // emoji/symbol only

      const isTextLeaf = (el) =>
        el.textContent.trim() &&
        ![...el.children].some(c => c.textContent.trim()) &&
        !isDecor(el);

      // Lines the author declared (<br> + 1) vs lines the browser actually drew.
      // A 3-line description written with two <br> is intentional; the same block
      // rendering 4 lines means it auto-wrapped — that is the R-1 symptom.
      const declaredLines = (el) => el.innerHTML.split(/<br\s*\/?>/i).length;
      const renderedLines = (el, cs) => {
        let lh = parseFloat(cs.lineHeight);
        if (!isFinite(lh)) lh = parseFloat(cs.fontSize) * 1.2;
        return Math.max(1, Math.round(el.getBoundingClientRect().height / lh));
      };

      // ── type scale + palette actually used ──────────────────────────
      const sizes = new Set(), colors = new Set(), backgrounds = new Set();
      for (const el of all) {
        const cs = getComputedStyle(el);
        if (isTextLeaf(el)) {
          sizes.add(Math.round(parseFloat(cs.fontSize) * 10) / 10);
          const c = rgbToHex(cs.color); if (c) colors.add(c);
        }
        const b = rgbToHex(cs.backgroundColor); if (b) backgrounds.add(b);
      }
      // The headline is not a text leaf when it wraps a .hl span — add it explicitly.
      const headEl = slide.querySelector('.headline');
      if (headEl) sizes.add(Math.round(parseFloat(getComputedStyle(headEl).fontSize) * 10) / 10);

      const offScale = [...sizes].filter(s => !SCALE.some(v => Math.abs(v - s) < 0.6));
      const offPalette = [...colors, ...backgrounds]
        .filter(c => !PALETTE.includes(c.toLowerCase()));

      // ── emphasis ratio ──────────────────────────────────────────────
      // The eyebrow belongs to the head unit, not to the body — it is a label
      // above the headline, so it does not compete for the protagonist slot.
      const head = slide.querySelector('.headline');
      const headSize = head ? parseFloat(getComputedStyle(head).fontSize) : null;
      const eyebrowEl = slide.querySelector('.eyebrow');
      const eyebrowSize = eyebrowEl ? Math.round(parseFloat(getComputedStyle(eyebrowEl).fontSize) * 10) / 10 : null;
      const bodySizes = [...sizes]
        .filter(s => !headSize || s < headSize)
        .filter(s => s !== eyebrowSize);
      const maxBody = bodySizes.length ? Math.max(...bodySizes) : null;

      // ── auto-wrapped / overflowing text leaves ──────────────────────
      const wrapped = [], overflow = [];
      for (const el of all) {
        if (!isTextLeaf(el)) continue;
        const cs = getComputedStyle(el);
        const r = el.getBoundingClientRect();
        const label = (el.className || el.tagName).toString().split(' ')[0];
        const text = el.textContent.trim().slice(0, 40);
        const declared = declaredLines(el), rendered = renderedLines(el, cs);
        if (rendered > declared)
          wrapped.push({ el: label, text, declared, rendered, fontSize: parseFloat(cs.fontSize) });
        if (el.scrollWidth > el.clientWidth + 1 || r.right > sr.right - 10)
          overflow.push({ el: label, text, right: +r.right.toFixed(1) });
      }

      // ── visual grouping (axis G) ────────────────────────────────────
      // A "surface" is anything drawing its own card: a background or a shadow.
      // Only the OUTERMOST surfaces count — a divider-split column inside a card
      // is not a separate chunk, which is the whole point of the grouping axis.
      const isSurface = (el) => {
        if (el.classList.contains('footer') || el.classList.contains('guides')) return false;
        if (DECOR.some(c => el.classList.contains(c))) return false; // .hl box, .bar tick, icon disc
        const r = el.getBoundingClientRect();
        if (r.width * r.height < 15000) return false;                // ornament, not a chunk
        const cs = getComputedStyle(el);
        return !!(rgbToHex(cs.backgroundColor) || cs.boxShadow !== 'none');
      };
      const outerSurfaces = all.filter(el => {
        if (!isSurface(el)) return false;
        for (let p = el.parentElement; p && p !== slide; p = p.parentElement)
          if (isSurface(p)) return false;
        return true;
      });
      const surfaces = outerSurfaces.map(el => {
        const r = el.getBoundingClientRect(), cs = getComputedStyle(el);
        return {
          el: (el.className || el.tagName).toString().split(' ')[0],
          x: +(r.left - sr.left).toFixed(1), y: +(r.top - sr.top).toFixed(1),
          w: +r.width.toFixed(1), h: +r.height.toFixed(1),
          radius: cs.borderRadius,
        };
      });
      // A uniform grid of identical cards reads as ONE chunk, not N — collapse
      // surfaces that share class and size into a single group before counting.
      const groupKey = (s) => `${s.el}|${Math.round(s.w)}x${Math.round(s.h)}`;
      const groups = {};
      for (const s of surfaces) (groups[groupKey(s)] ||= []).push(s);
      const blocks = surfaces;

      // ── per-card bullet counts (R-5) ────────────────────────────────
      const bulletGroups = [...slide.querySelectorAll('ul')].map(ul => ul.children.length);

      return {
        canvas: { w: +sr.width.toFixed(1), h: +sr.height.toFixed(1) },
        typeScale: [...sizes].sort((a, b) => a - b),
        offScale,
        colors: [...colors].sort(),
        backgrounds: [...backgrounds].sort(),
        offPalette: [...new Set(offPalette)],
        headline: { size: headSize, maxBody, ratio: headSize && maxBody ? +(headSize / maxBody).toFixed(2) : null },
        highlightCount: slide.querySelectorAll('.hl').length,
        metaRows: slide.querySelectorAll('.meta-row').length,
        surfaces: blocks,
        surfaceCount: surfaces.length,
        surfaceGroups: Object.keys(groups).length,
        surfaceGroupDetail: Object.entries(groups).map(([k, v]) => ({ group: k, n: v.length })),
        bulletGroups,
        bulletCountsEqual: new Set(bulletGroups).size <= 1,
        autoWrapped: wrapped,
        overflowing: overflow,
        images: [...slide.querySelectorAll('img')].map(i => ({
          src: i.getAttribute('src'),
          natural: [i.naturalWidth, i.naturalHeight],
          rendered: [Math.round(i.getBoundingClientRect().width), Math.round(i.getBoundingClientRect().height)],
          objectFit: getComputedStyle(i).objectFit,
        })),
        emptySlots: slide.querySelectorAll('.slot--empty, .kard-photo, .photo').length,
      };
    }, { SCALE, PALETTE });

    console.log(JSON.stringify({ file: path.basename(abs), ...data }, null, 2));
  }

  await browser.close();
})();
