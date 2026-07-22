# Modulo Squares web

React 19, TypeScript, Vite 8, and Tailwind CSS 4 website for `modulosquares.com`.

## Commands

```bash
npm install
npm run dev
npm run lint
npm run build
npm run preview
```

The production build is written to `dist/` and deployed by `.github/workflows/ci-cd.yml` to Firebase Hosting.

Routes: `/`, `/how-it-works`, `/download`, `/pricing`, `/leaderboard`, `/privacy`, `/terms`, `/cookies`, and `/support`.

The leaderboard reads public Firestore collections. Google Tag Manager/GA4 and AdSense are consent-controlled; Firebase Analytics is not initialized on the website. Production Firebase and AdSense values are supplied through Vite environment variables.

See [Web Frontend Architecture](../../docs/Web_Frontend_Architecture.md).
