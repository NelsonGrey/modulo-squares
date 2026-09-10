/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_SHOW_COMING_SOON: string
  readonly VITE_ENVIRONMENT: string

  // Firebase web config
  readonly VITE_FIREBASE_API_KEY: string
  readonly VITE_FIREBASE_AUTH_DOMAIN: string
  readonly VITE_FIREBASE_PROJECT_ID: string
  readonly VITE_FIREBASE_STORAGE_BUCKET: string
  readonly VITE_FIREBASE_MESSAGING_SENDER_ID: string
  readonly VITE_FIREBASE_APP_ID: string

  // EnvironmentGate allowlist (dev/staging web only; injected at build time)
  readonly VITE_ALLOWED_EMAILS: string
  readonly VITE_ALLOWED_EMAIL_DOMAINS: string

  // Google AdSense
  readonly VITE_ADSENSE_PUBLISHER_ID: string
  readonly VITE_ADSENSE_SLOT_BELOW_HEADER: string
  readonly VITE_ADSENSE_SLOT_ABOVE_FOOTER: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
