#!/usr/bin/env node
// Repository-managed rendering dependency for render-assets.sh.
//
// Loads `render.html` with the given query string in a headless Chromium
// instance, waits for it to report readiness (see render.html's
// `document.body.dataset.ready` marker), and screenshots the result. This
// replaces the previous dependency on a private Playwright wrapper installed
// under `$CODEX_HOME/skills`, which was not checked into the repository and
// could not be installed on another machine or in CI.
//
// Setup (one-time, from the repository root):
//   npm install
//   npx playwright install --with-deps chromium
//
// Usage:
//   node scripts/store-promo/capture.mjs <width> <height> <url> <output-path>

import { chromium } from 'playwright';

const [, , widthArg, heightArg, url, outputPath] = process.argv;

if (!widthArg || !heightArg || !url || !outputPath) {
  console.error(
    'Usage: capture.mjs <width> <height> <url> <output-path>',
  );
  process.exit(1);
}

const width = Number.parseInt(widthArg, 10);
const height = Number.parseInt(heightArg, 10);

if (!Number.isFinite(width) || !Number.isFinite(height)) {
  console.error(`Invalid dimensions: ${widthArg}x${heightArg}`);
  process.exit(1);
}

const browser = await chromium.launch();
try {
  const page = await browser.newPage({ viewport: { width, height } });
  page.on('pageerror', (error) => console.error('Page error:', error));

  await page.goto(url, { waitUntil: 'load' });

  // render.html sets data-ready to 'true' once every visible <img> has
  // loaded, or 'false' (with data-ready-error) the moment one fails --
  // fail the capture instead of screenshotting incomplete artwork.
  await page.waitForFunction(
    () => document.body.dataset.ready === 'true' || document.body.dataset.ready === 'false',
    { timeout: 15000 },
  );

  const { ready, error } = await page.evaluate(() => ({
    ready: document.body.dataset.ready,
    error: document.body.dataset.readyError,
  }));

  if (ready !== 'true') {
    throw new Error(
      `render.html failed to load its source image(s) for ${url}: ${error || 'unknown error'}`,
    );
  }

  await page.screenshot({ path: outputPath });
} finally {
  await browser.close();
}
