import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [tailwindcss(), react()],
  resolve: {
    dedupe: ['react', 'react-dom', 'react-router-dom', 'react-router'],
  },
  build: {
    outDir: 'dist',
    sourcemap: false, // Disable sourcemaps for production
    minify: 'terser', // Use terser for better minification
    rollupOptions: {
      output: {
        manualChunks: (id) => {
          // Vendor chunks for better caching
          if (id.includes('node_modules')) {
            if (id.includes('react') || id.includes('react-dom')) {
              return 'react-vendor';
            }
            if (id.includes('firebase')) {
              return 'firebase-vendor';
            }
            return 'vendor';
          }
          // Game logic chunk
          if (id.includes('shared/models') || id.includes('features/game')) {
            return 'game-logic';
          }
        },
      },
    },
    // Enable gzip compression reporting
    reportCompressedSize: true,
    // Set chunk size warnings
    chunkSizeWarningLimit: 1000,
  },
  server: {
    port: 3000,
    host: true,
  },
})