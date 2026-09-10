# SEO / SEM & Google Tools Audit

**Date:** 2026-09-10
**Scope:** `packages/web/` (Vite/React SPA), `packages/mobile/ios/fastlane/`, `firebase.json`, GTM/GA4/AdSense config.
Companion to [`Analytics.md`](Analytics.md).

Items marked **[verify]** need a console check (GTM / GA4 / Search Console / AdSense / App Store Connect) and cannot be confirmed from the repo.

---

## Google tools

| Tool | State | Notes |
|---|---|---|
| GTM `GTM-TR4PP272` | Installed, Consent Mode v2 defaults set before load, foreign tags purged 2026-07-31 | Container internals not in repo. **[verify]** a History-Change (or `page_view` custom-event) trigger → GA4 event tag exists |
| GA4 `G-FY0QLHWYJN` (prop `508678430`, web+iOS+Android) | Loaded via GTM only — no legacy analytics.js/gtag.js | Site emitted **no custom events** until this PR; **[verify]** GA4 tag has a consent check (runbook line 664) |
| Search Console | API access via `marketing-tools-service@` | No verification token/file in repo. **[verify]** ownership, sitemap submission, Coverage report given the SPA |
| AdSense `ca-pub-5198775482699756` | `adsbygoogle.js` in `<head>`, `ads.txt` + `app-ads.txt` correct | **[verify]** re-approval after the thin-content rejection; the justifying content pages are not crawler-visible without JS (see below) |
| Google Ads | Not connected (needs developer-token application) | Defer until a paid campaign is decided; note there is no gtag conversion/remarketing tag wired |
| Apple Search Ads | Nothing | No `AdServices` attribution API in the app → iOS paid search would be unmeasurable |

## Website SEO

**Good:** every route uses `SEOHead` (unique title/description/canonical/OG/Twitter); `robots.txt` + `sitemap.xml`; two long-form content pages; `assetlinks.json` (Android deep links); GTM is the only tag loader.

**Gaps (impact order):**

1. **Client-only rendering.** Firebase rewrites `** → /index.html`; per-route meta/JSON-LD only exist after React runs. Googlebot renders JS (delayed); Bing, DuckDuckGo, social scrapers and LLM crawlers see the homepage meta for every URL. Fix: prerender the marketing routes at build (`vite-plugin-prerender` / `react-snap` / puppeteer step in `build-web`) or Firebase SSR.
2. **No SPA route-change pageviews** *(partially fixed in this PR — needs the GTM trigger)*. `useLocation` was used only for nav styling.
3. **Thin structured data** *(improved in this PR)*. Was only `MobileApplication` on home, inconsistent `operatingSystem`. Still missing: `Article` on the two content pages, `FAQPage` on Support/How-It-Works, `BreadcrumbList`.
4. **Title / copy inconsistency** *(fixed in this PR)*.
5. **Canonical mismatch on home** *(fixed in this PR — trailing slash)*.
6. **Weak social image** *(fixed in this PR — 1280×720 + `summary_large_image`)*.
7. `Download.tsx` uses `<h2>` for its main heading (no `<h1>`); no Play Store link anywhere on the site despite "Android" copy.
8. **Core Web Vitals headwinds:** GTM + AdSense in `<head>`, no `preconnect` *(added in this PR)*; `firebase-vendor` chunk 538 KB; HTML served `no-store` (full revalidation every navigation).
9. Sitemap has no `<lastmod>`; `changefreq`/`priority` are largely ignored by Google; hand-maintained static file that will drift.
10. Non-prod hosts (gated) have no explicit `X-Robots-Tag: noindex` as defence-in-depth.

## Website SEM / measurement

- **No conversion events** until this PR (only consent updates fired `gtag`). App Store clicks, CTA clicks, pricing views — untracked. GA4/GTM had nothing to build an audience or conversion on.
- No outbound-link tracking to `apps.apple.com`.
- No UTM capture / campaign attribution on the site (the `vehicle-vitals` pattern is not present here).

## iOS ASO + web↔app

**Good:** structured `description.txt`, all listing fields present, 6 version-controlled screenshots, `marketing_url` → site.

**Gaps:**

1. **No Universal Links.** No `associated-domains` entitlement, no `apple-app-site-association` file (Android has `assetlinks.json`). Links to the site can't open the app; no deep-link attribution.
2. **No Smart App Banner** *(added in this PR — `apple-itunes-app` app-id=6783995654)*.
3. **Subtitle wasted ASO space** *(changed in this PR — "Drop Numbers. Think Fast." → "Divisibility Number Puzzle")*. Visible change; takes effect on the next `deliver` + App Review.
4. **Keyword field** *(tightened in this PR)* — removed terms now covered by the subtitle/name; added `brain teaser`, `mental math`, `number game`, `iq`, `factors`, `concentration`, `division`.
5. **English-only.** No localized listings/keywords — the highest-leverage remaining ASO move for a language-agnostic number game.
6. No Apple Search Ads attribution (`AdServices` / `AAAttribution.attributionToken()`).
7. Play Store: decent, but no promo video wired (the kit has `modulo-squares-youtube-promo-1920x1080.mp4`), English-only, still gated by closed testing.
8. Analytics funnel gaps (see `Analytics.md`): falling-mode screen doesn't emit `level_start`/`level_complete`; several events are legacy-board leftovers.

---

## What this PR changed

- `index.html`: Smart App Banner meta; `preconnect`/`dns-prefetch` for GTM/AdSense/GA; OG/Twitter → 1280×720 image + `summary_large_image`; standardized description; JSON-LD `@graph` with `Organization` + `WebSite` + a corrected `MobileApplication` (`operatingSystem: iOS`, `installUrl`, `author`/`publisher`).
- `public/og-image-1280x720.png` — from the promo kit.
- `SEOHead.tsx`: default image → 1280×720, `summary_large_image`, home canonical gets a trailing slash.
- `utils/analytics.ts` + `components/RouteAnalytics.tsx`: `trackEvent()` dataLayer helper; `page_view` pushed for every view including the initial one (deferred one frame so the route `<title>` has flushed). Requires the GA4 config tag's automatic page_view to be **disabled** so this is the single source.
- `Download.tsx` / `Hero.tsx`: `app_store_click` and `cta_click` events on the primary CTAs; App Store link opens in a new tab.
- `Hero.tsx` `APP_JSON_LD`: aligned copy, `operatingSystem: iOS`, `installUrl`, `author`/`publisher`.
- iOS `subtitle.txt` / `keywords.txt`.

## Remaining punch list

**Needs a console action ([verify] / configure)**
- GTM: add a trigger on the `page_view` custom event (or History Change) → GA4 event tag, **and disable the GA4 config tag's automatic page_view** (RouteAnalytics now owns all of them, initial included); mark `app_store_click` / `cta_click` as conversions; confirm the GA4 tag has a consent check.
- Search Console: confirm ownership, submit the sitemap, review Coverage.
- AdSense: confirm re-approval.

**Medium (code)**
- Prerender the marketing routes at build time (unblocks content pages *and* the AdSense justification).
- `apple-app-site-association` + `associated-domains` entitlement for Universal Links.
- `Article` (content pages) + `FAQPage` (Support) JSON-LD; generate the sitemap at build with `lastmod`; give `Download.tsx` an `<h1>`.
- Wire falling-mode `level_start`/`level_complete` + the activation funnel events (`Analytics.md` §"Recommended current funnel").
- UTM capture + persistence on the site.

**Later / decision-gated**
- iOS localizations + localized keywords.
- `AdServices` attribution + Apple Search Ads; Google Ads developer token + gtag conversion/remarketing — once a paid budget is committed.
- Play Store promo video + localizations after the closed-testing gate clears.
