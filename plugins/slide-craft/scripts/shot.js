const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const files = process.argv.slice(2);
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 }, deviceScaleFactor: 1 });
  for (const f of files) {
    const abs = path.resolve(f);
    await page.goto('file://' + abs);
    await page.waitForTimeout(250);
    const out = abs.replace(/\.html$/, '.png');
    const el = await page.$('.slide');
    await (el ? el.screenshot({ path: out }) : page.screenshot({ path: out }));
    console.log('->', out);
  }
  await browser.close();
})();
