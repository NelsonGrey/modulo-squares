# Web Frontend Architecture

**Updated**: 2026-07-20
**Deployed application**: `packages/web`

## Stack

- React `19`
- React Router `7`
- TypeScript `6`
- Vite `8`
- Tailwind CSS `4`
- Firebase Web SDK `12`
- React Helmet Async for route metadata
- Nginx container for static hosting outside Firebase

## Routes

| Route | Component | Purpose |
|---|---|---|
| `/` | `Hero` | Product story and core CTA |
| `/how-it-works` | `Features` | Falling-mode explanation |
| `/download` | `Download` | iOS-focused acquisition page |
| `/pricing` | `Pricing` | Free and Remove Ads positioning |
| `/leaderboard` | `Leaderboard` | Live global/current-week scores |
| `/privacy` | `PrivacyPolicy` | Privacy disclosure |
| `/terms` | `TermsOfService` | Terms |
| `/cookies` | `CookiePolicy` | Website cookie disclosure |
| `/support` | `Support` | Help and contact guidance |

`VITE_SHOW_COMING_SOON=true` replaces all routes with the `ComingSoon` component.

## Component layout

`Layout` wraps navigation, optional AdSense placements, route content, consent banner, and footer. Route pages use `SEOHead` to set canonical metadata.

The navigation exposes How It Works, Download, Pricing, and Leaderboard. Legal/support links live in the footer.

## Firebase

`src/firebase.ts` initializes only Firebase App and Firestore. Web analytics is intentionally not initialized through Firebase.

The leaderboard establishes live listeners for:

- `modulo_leaderboard`, ordered by `score desc`, limit 50;
- `modulo_weekly_leaderboard/{weekId}/scores`, ordered by `score desc`, limit 50.

The weekly identifier matches the Dart client: one-based seven-day buckets starting January 1, not ISO week numbers.

## Analytics, advertising, and consent

`index.html` initializes Google Consent Mode before loading GTM container `GTM-TR4PP272`. Default storage is denied. A saved `ms_consent_v1` choice may restore consent synchronously.

The React `ConsentBanner` updates consent and notifies `AdSlot` components. AdSense uses publisher `ca-pub-5198775482699756`; slot IDs are Vite environment variables.

Keep these statements synchronized:

- `PrivacyPolicy.tsx`
- `CookiePolicy.tsx`
- consent bootstrap in `index.html`
- `src/utils/consent.ts`
- `AdSlot.tsx`
- actual GTM/GA4 and AdSense console configuration

## SEO

- Each route supplies title, description, canonical path, Open Graph, and related metadata through `SEOHead`.
- `public/robots.txt` permits crawling and names the sitemap.
- `public/sitemap.xml` lists all nine public routes.
- Icon and manifest assets are under `public`.

Update the sitemap whenever an indexable route is added or removed.

## Build and hosting

```bash
cd packages/web
npm ci
npm run lint
npm run build
```

Vite writes `dist`. Firebase Hosting points `public` to `packages/web/dist` and rewrites unknown paths to `/index.html` for client routing. `nginx.conf` provides equivalent SPA fallback for the Docker image.

## Environment variables

Required Firebase values:

- `VITE_FIREBASE_API_KEY`
- `VITE_FIREBASE_AUTH_DOMAIN`
- `VITE_FIREBASE_PROJECT_ID`
- `VITE_FIREBASE_STORAGE_BUCKET`
- `VITE_FIREBASE_MESSAGING_SENDER_ID`
- `VITE_FIREBASE_APP_ID`

Advertising values:

- `VITE_ADSENSE_PUBLISHER_ID`
- `VITE_ADSENSE_SLOT_BELOW_HEADER`
- `VITE_ADSENSE_SLOT_ABOVE_FOOTER`

Optional:

- `VITE_SHOW_COMING_SOON`

Firebase web API keys are identifiers and may be public, but they still require API restrictions, quotas, and App Check/rules enforcement.

## Known gaps

- No dedicated web unit, accessibility, or end-to-end test suite.
- Live leaderboard errors are shown generically and are not retried in-app.
- Analytics and AdSense console configuration cannot be proven from source alone.
- Consent preference reset currently depends on clearing site storage; there is no persistent settings control.
