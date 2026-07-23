#!/usr/bin/env python3
"""slide-craft render verification gate.

Renders an HTML slide with Chromium (via Playwright) and applies quantitative gates that a
human reviewer cannot reliably apply by reading markup.

Usage:
    python3 slide_qa.py <slide.html> [--out DIR] [options]
    python3 slide_qa.py <slide.html> --pdf --page-size A3-landscape --expect-pages 1

Outputs:
    <out>/<name>.png       full-page render
    <out>/<name>@50.png    50%-scale render (viewing-distance simulation)
    <out>/<name>.pdf       only with --pdf
    a measurement report on stdout (add --json for machine-readable)

Hard gates (exit 1):
    font floor      text rendered below the readable floor
    occupancy       full-width boxes whose content fills less than the threshold
    clipping        elements pushed outside the document bounds
    external        ANY network request outside file:// or data: (the no-CDN rule)
    contrast        text below the minimum contrast ratio against a solid background
    pages           PDF page count != --expect-pages (only when --pdf --expect-pages given)

Reported but NOT a hard gate:
    overlaps        overlapping absolutely-positioned siblings (layering is often intentional)
                    -- every reported pair still has to be judged in the PNG

Requires: playwright  (pip install playwright && playwright install chromium)
"""
import argparse
import json
import os
import re
import sys

PAGE_SIZES = {
    "A3": ("297mm", "420mm"),
    "A3-landscape": ("420mm", "297mm"),
    "A4": ("210mm", "297mm"),
    "A4-landscape": ("297mm", "210mm"),
    "letter": ("8.5in", "11in"),
    "letter-landscape": ("11in", "8.5in"),
}

MEASURE_JS = r"""
(cfg) => {
  const W = document.documentElement.scrollWidth, H = document.documentElement.scrollHeight;
  const vis = el => {
    const c = getComputedStyle(el);
    return c.display !== 'none' && c.visibility !== 'hidden' && parseFloat(c.opacity || 1) > 0;
  };
  const sel = el => {
    let s = el.tagName.toLowerCase();
    if (el.id) return s + '#' + el.id;
    if (el.className && typeof el.className === 'string') {
      const cls = el.className.trim().split(/\s+/).filter(Boolean).slice(0, 2);
      if (cls.length) s += '.' + cls.join('.');
    }
    return s;
  };

  const parseRGB = str => {
    const m = String(str).match(/rgba?\(([^)]+)\)/);
    if (!m) return null;
    const p = m[1].split(',').map(x => parseFloat(x));
    return { r: p[0], g: p[1], b: p[2], a: p.length > 3 ? p[3] : 1 };
  };
  const lum = c => {
    const f = v => { v /= 255; return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); };
    return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b);
  };
  const over = (fg, bg) => ({                       // composite fg (with alpha) onto opaque bg
    r: fg.r * fg.a + bg.r * (1 - fg.a),
    g: fg.g * fg.a + bg.g * (1 - fg.a),
    b: fg.b * fg.a + bg.b * (1 - fg.a), a: 1
  });
  // Walk up for the effective background. Returns null when an ancestor paints a
  // gradient/image, because that cannot be reduced to one comparable colour.
  const effBg = el => {
    let node = el, acc = null;
    while (node && node !== document.documentElement.parentNode) {
      const c = getComputedStyle(node);
      if (c.backgroundImage && c.backgroundImage !== 'none') return null;
      const bg = parseRGB(c.backgroundColor);
      if (bg && bg.a > 0) {
        acc = acc === null ? bg : over(acc, bg);
        if (acc.a >= 0.999) return acc;
      }
      node = node.parentElement;
    }
    if (acc && acc.a >= 0.999) return acc;
    return over(acc || { r: 255, g: 255, b: 255, a: 0 }, { r: 255, g: 255, b: 255, a: 1 });
  };

  const out = {
    doc: { w: W, h: H },
    fonts: {}, small: [], boxes: [], overlaps: [], clipped: [],
    lowContrast: [], lowContrastGlyphs: [], contrastSkipped: 0, fontFamilies: {}
  };

  // ---- text-bearing elements: font size + contrast -------------------------------------
  const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
  const seen = new Set();
  while (walker.nextNode()) {
    const el = walker.currentNode.parentElement;
    const txt = walker.currentNode.textContent.trim();
    if (!el || !txt || seen.has(el) || !vis(el)) continue;
    seen.add(el);
    const c = getComputedStyle(el);
    const fs = Math.round(parseFloat(c.fontSize) * 10) / 10;
    const fw = parseInt(c.fontWeight, 10) || 400;
    out.fonts[fs] = (out.fonts[fs] || 0) + 1;
    const fam = (c.fontFamily || '').split(',')[0].replace(/['"]/g, '').trim();
    if (fam) out.fontFamilies[fam] = (out.fontFamilies[fam] || 0) + 1;
    if (fs < cfg.floor) out.small.push({ fs, sel: sel(el), text: txt.slice(0, 40) });

    const fg = parseRGB(c.color), bg = effBg(el);
    if (!fg || !bg) { out.contrastSkipped++; continue; }
    const solid = fg.a >= 0.999 ? fg : over(fg, bg);
    const l1 = lum(solid), l2 = lum(bg);
    const ratio = Math.round(((Math.max(l1, l2) + 0.05) / (Math.min(l1, l2) + 0.05)) * 100) / 100;
    const large = fs >= 24 || (fs >= 18.66 && fw >= 700);
    // A 1-2 char run with no letters/digits is a decorative glyph (the CDN-free icon
    // substitute), not prose. Report it, but do not hard-fail on it.
    const decorative = txt.length <= 2 && !/[\p{L}\p{N}]/u.test(txt);
    if (ratio < cfg.contrast) {
      const rec = { ratio, fs, large, sel: sel(el), text: txt.slice(0, 40) };
      (decorative ? out.lowContrastGlyphs : out.lowContrast).push(rec);
    }
  }

  // ---- boxes: content occupancy --------------------------------------------------------
  for (const el of document.body.querySelectorAll('*')) {
    if (!vis(el)) continue;
    const r = el.getBoundingClientRect();
    const c = getComputedStyle(el);
    if (r.width < cfg.boxMin || r.height < 24 || r.height > cfg.boxMaxH) continue;
    const boxed = parseFloat(c.borderTopWidth) > 0 ||
      (c.backgroundColor !== 'rgba(0, 0, 0, 0)' && c.backgroundColor !== 'rgb(255, 255, 255)') ||
      (c.backgroundImage && c.backgroundImage !== 'none');
    if (!boxed) continue;
    // rightmost real glyph -- block children fill the width and would overstate occupancy
    let right = r.left;
    const tw = document.createTreeWalker(el, NodeFilter.SHOW_TEXT);
    while (tw.nextNode()) {
      const t = tw.currentNode;
      if (!t.textContent.trim() || !t.parentElement || !vis(t.parentElement)) continue;
      const rg = document.createRange(); rg.selectNodeContents(t);
      const tr = rg.getBoundingClientRect();
      if (tr.width > 0) right = Math.max(right, tr.right);
    }
    if (right === r.left) continue;   // purely visual element (rings, rails) -- not measurable
    out.boxes.push({
      sel: sel(el), w: Math.round(r.width),
      occ: Math.round(((right - r.left) / r.width) * 100) / 100
    });
  }

  // ---- absolutely positioned elements: clipping + sibling overlap ----------------------
  const abs = [...document.body.querySelectorAll('*')]
    .filter(el => vis(el) && getComputedStyle(el).position === 'absolute');
  for (const el of abs) {
    const r = el.getBoundingClientRect();
    if (r.width === 0 || r.height === 0) continue;
    if (r.right > W + 2 || r.bottom > H + 2 || r.left < -2 || r.top < -2) {
      out.clipped.push({
        sel: sel(el), left: Math.round(r.left), top: Math.round(r.top),
        right: Math.round(r.right), bottom: Math.round(r.bottom)
      });
    }
  }
  for (let i = 0; i < abs.length; i++) {
    for (let j = i + 1; j < abs.length; j++) {
      const a = abs[i], b = abs[j];
      if (a.contains(b) || b.contains(a) || a.parentElement !== b.parentElement) continue;
      const ra = a.getBoundingClientRect(), rb = b.getBoundingClientRect();
      const ox = Math.min(ra.right, rb.right) - Math.max(ra.left, rb.left);
      const oy = Math.min(ra.bottom, rb.bottom) - Math.max(ra.top, rb.top);
      if (ox > 4 && oy > 4) out.overlaps.push({ a: sel(a), b: sel(b), area: Math.round(ox * oy) });
    }
  }
  return out;
}
"""


def count_pdf_pages(path):
    """Page count without a PDF library. /Count in the page tree first, /Type /Page as fallback."""
    with open(path, "rb") as fh:
        data = fh.read()
    counts = [int(m) for m in re.findall(rb"/Type\s*/Pages[^>]*?/Count\s+(\d+)", data, re.S)]
    if not counts:
        counts = [int(m) for m in re.findall(rb"/Count\s+(\d+)\s*/Type\s*/Pages", data, re.S)]
    if counts:
        return max(counts)
    return len(re.findall(rb"/Type\s*/Page(?![s/\w])", data))


def launch(pw, headless=True):
    """Prefer the installed Chrome channel, fall back to bundled Chromium."""
    try:
        return pw.chromium.launch(channel="chrome", headless=headless)
    except Exception:
        return pw.chromium.launch(headless=headless)


def main():
    ap = argparse.ArgumentParser(description="slide-craft render verification gate")
    ap.add_argument("html", help="path to the slide HTML")
    ap.add_argument("--out", default="/tmp/slide-qa", help="output directory for PNG/PDF")
    ap.add_argument("--width", type=int, default=1700, help="viewport width (default 1700)")
    ap.add_argument("--height", type=int, default=1150, help="viewport height (default 1150)")
    ap.add_argument("--font-floor", type=float, default=13.0,
                    help="minimum rendered font size in px (default 13)")
    ap.add_argument("--fullwidth-min", type=int, default=1200,
                    help="width in px at which a box counts as full-width (default 1200)")
    ap.add_argument("--occupancy", type=float, default=0.67,
                    help="minimum content occupancy of a full-width box (default 0.67)")
    ap.add_argument("--box-min", type=int, default=350,
                    help="smallest box width to measure occupancy on (default 350)")
    ap.add_argument("--box-max-height", type=int, default=500,
                    help="tallest box to measure occupancy on (default 500)")
    ap.add_argument("--contrast", type=float, default=3.0,
                    help="minimum text contrast ratio, 0 disables (default 3.0)")
    ap.add_argument("--pdf", action="store_true", help="also render a PDF")
    ap.add_argument("--page-size", default="A3-landscape",
                    choices=sorted(PAGE_SIZES) + ["custom"],
                    help="PDF page size (default A3-landscape)")
    ap.add_argument("--custom-size", help='with --page-size custom, e.g. "420mm,297mm"')
    ap.add_argument("--expect-pages", type=int,
                    help="fail if the PDF page count differs from this")
    ap.add_argument("--allow-external", action="store_true",
                    help="do not fail on external resource requests (discouraged)")
    ap.add_argument("--no-shrink", action="store_true", help="skip the 50%% render")
    ap.add_argument("--json", action="store_true", help="emit a JSON report instead of text")
    args = ap.parse_args()

    html = os.path.abspath(args.html)
    if not os.path.isfile(html):
        sys.exit(f"not found: {html}")
    os.makedirs(args.out, exist_ok=True)
    name = os.path.splitext(os.path.basename(html))[0]
    png = os.path.join(args.out, name + ".png")
    png50 = os.path.join(args.out, name + "@50.png")
    pdf = os.path.join(args.out, name + ".pdf")

    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        sys.exit("playwright missing: pip install playwright && playwright install chromium")

    external = []
    cfg = {
        "floor": args.font_floor, "contrast": args.contrast if args.contrast > 0 else 0,
        "boxMin": args.box_min, "boxMaxH": args.box_max_height,
    }

    with sync_playwright() as pw:
        browser = launch(pw)
        ctx = browser.new_context(viewport={"width": args.width, "height": args.height})

        def on_request(req):
            url = req.url
            if not (url.startswith("file://") or url.startswith("data:") or url.startswith("about:")):
                external.append({"url": url[:200], "type": req.resource_type})

        ctx.on("request", on_request)
        page = ctx.new_page()
        page.goto("file://" + html)
        try:
            page.wait_for_load_state("networkidle", timeout=10000)
        except Exception:
            pass
        page.wait_for_timeout(300)
        page.screenshot(path=png, full_page=True)
        m = page.evaluate(MEASURE_JS, cfg)

        if args.pdf:
            if args.page_size == "custom":
                if not args.custom_size:
                    sys.exit("--page-size custom requires --custom-size 'W,H'")
                w, h = [s.strip() for s in args.custom_size.split(",")]
            else:
                w, h = PAGE_SIZES[args.page_size]
            page.pdf(path=pdf, width=w, height=h, print_background=True,
                     margin={"top": "0", "right": "0", "bottom": "0", "left": "0"})

        if not args.no_shrink:
            ctx50 = browser.new_context(
                viewport={"width": args.width, "height": args.height}, device_scale_factor=0.5)
            p50 = ctx50.new_page()
            p50.goto("file://" + html)
            p50.wait_for_timeout(250)
            p50.screenshot(path=png50, full_page=True)
            ctx50.close()

        browser.close()

    # ---- gates ---------------------------------------------------------------------------
    occ_fail = [b for b in m["boxes"]
                if b["w"] >= args.fullwidth_min and b["occ"] < args.occupancy]
    occ_warn = sorted((b for b in m["boxes"]
                       if b["w"] < args.fullwidth_min and b["occ"] < 0.5),
                      key=lambda b: b["occ"])[:8]
    ext_fail = [] if args.allow_external else external
    page_count = count_pdf_pages(pdf) if args.pdf and os.path.isfile(pdf) else None
    page_fail = (args.expect_pages is not None and page_count is not None
                 and page_count != args.expect_pages)

    failures = {
        "font_floor": m["small"],
        "occupancy": occ_fail,
        "clipped": m["clipped"],
        "external": ext_fail,
        "contrast": m["lowContrast"],
        "pages": ([{"expected": args.expect_pages, "actual": page_count}] if page_fail else []),
    }
    failed = any(v for v in failures.values())

    if args.json:
        print(json.dumps({
            "html": html, "png": png, "png50": None if args.no_shrink else png50,
            "pdf": pdf if args.pdf else None, "pdfPages": page_count,
            "verdict": "FAIL" if failed else "PASS",
            "failures": failures,
            "overlaps": m["overlaps"], "occupancyWarn": occ_warn,
            "lowContrastGlyphs": m["lowContrastGlyphs"],
            "fontHistogram": m["fonts"], "fontFamilies": m["fontFamilies"],
            "contrastSkipped": m["contrastSkipped"], "doc": m["doc"],
        }, ensure_ascii=False, indent=2))
        sys.exit(1 if failed else 0)

    print(f"PNG      : {png}")
    if not args.no_shrink:
        print(f"PNG @50% : {png50}")
    if args.pdf:
        print(f"PDF      : {pdf}  ({page_count} page(s))")
    print(f"document : {m['doc']['w']} x {m['doc']['h']} px\n")

    hist = " · ".join(f"{k}px×{v}" for k, v in sorted(m["fonts"].items(), key=lambda x: float(x[0])))
    print(f"[font distribution] {hist}")
    fams = " · ".join(f"{k}({v})" for k, v in
                      sorted(m["fontFamilies"].items(), key=lambda x: -x[1])[:6])
    print(f"[font families] {fams}")

    print(f"[GATE font-floor <{args.font_floor}px] {len(m['small'])} violation(s)")
    for s in m["small"][:15]:
        print(f"    {s['fs']}px  {s['sel']}  \"{s['text']}\"")
    if len(m["small"]) > 15:
        print(f"    … and {len(m['small']) - 15} more")

    print(f"[GATE occupancy — boxes ≥{args.fullwidth_min}px filling <{args.occupancy:.0%}] "
          f"{len(occ_fail)} violation(s)")
    for b in occ_fail:
        print(f"    {b['sel']}  w={b['w']}px  filled {int(b['occ'] * 100)}%")
    print(f"[note — narrow boxes filling <50%] {len(occ_warn)} (judge by eye: intentional or empty?)")
    for b in occ_warn:
        print(f"    {b['sel']}  w={b['w']}px  filled {int(b['occ'] * 100)}%")

    print(f"[GATE clipped outside document] {len(m['clipped'])}")
    for c in m["clipped"]:
        print(f"    {c['sel']}  l={c['left']} t={c['top']} r={c['right']} b={c['bottom']}")

    print(f"[GATE external resources (no-CDN)] {len(external)}"
          + ("  (ignored: --allow-external)" if args.allow_external else ""))
    for e in external[:10]:
        print(f"    {e['type']}: {e['url']}")

    if args.contrast > 0:
        print(f"[GATE contrast <{args.contrast}:1] {len(m['lowContrast'])} violation(s)"
              f"   ({m['contrastSkipped']} skipped: gradient/image background)")
        for c in m["lowContrast"][:10]:
            print(f"    {c['ratio']}:1  {c['fs']}px  {c['sel']}  \"{c['text']}\"")
        if m["lowContrastGlyphs"]:
            print(f"[note — low-contrast decorative glyphs] {len(m['lowContrastGlyphs'])}"
                  " (not a gate; confirm they read at 50% scale)")
            for c in m["lowContrastGlyphs"][:6]:
                print(f"    {c['ratio']}:1  {c['fs']}px  {c['sel']}  \"{c['text']}\"")

    if args.expect_pages is not None:
        state = "OK" if not page_fail else f"FAIL (expected {args.expect_pages})"
        print(f"[GATE pdf page count] {page_count} — {state}")

    print(f"[report only — overlapping absolute siblings] {len(m['overlaps'])} pair(s)"
          " — judge each in the PNG; layering is sometimes intentional")
    for o in m["overlaps"][:10]:
        print(f"    {o['a']} ↔ {o['b']}  {o['area']}px²")

    print("\nVERDICT: " + ("FAIL — fix the gate violations above and re-measure"
                           if failed else
                           "PASS (quantitative gates) — now open both PNGs and judge by eye"))
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
