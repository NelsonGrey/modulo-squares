/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_SHOW_COMING_SOON: string
  // add more env variables as needed
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}