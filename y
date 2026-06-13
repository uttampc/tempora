import { defineConfig } from "vite";
import { VitePWA } from "vite-plugin-pwa";
import packageJson from './package.json' with { type: 'json' };
import fs from 'fs';

export default defineConfig({
  server: {
    host: true,
    https: {
      key: fs.readFileSync('key.pem'),
      cert: fs.readFileSync('cert.pem'),
    },
    port: 5173,
  },
  define: {
    __APP_VERSION__: JSON.stringify(packageJson.version),
  },
  plugins: [
    VitePWA({
      registerType: "autoUpdate",
      workbox: {
        // Cache everything in the app shell
        globPatterns: ['**/*.{js,css,html,ico,png,svg,woff2}'],
        // Cache API/fetch calls
        runtimeCaching: [],
      },
      includeAssets: ['icon.svg', 'apple-touch-icon.png'],
      manifest: {
        name: 'Centerline',
        short_name: 'Centerline',
        description: 'Guided movement for strength and recovery',
        theme_color: '#1a1a1a',
        background_color: '#ffffff',
        display: 'standalone',
        orientation: 'portrait',
        scope: '/',
        start_url: '/',
        icons: [
          {
            src: 'apple-touch-icon.png',
            sizes: '180x180',
            type: 'image/png',
          },
          {
            src: 'icon.svg',
            sizes: 'any',
            type: 'image/svg+xml',
            purpose: 'any',
          },
          {
            src: 'pwa-192x192.png',
            sizes: '192x192',
            type: 'image/png',
            purpose: 'any',
          },
          {
            src: 'pwa-512x512.png',
            sizes: '512x512',
            type: 'image/png',
            purpose: 'any',
          },
          {
            src: 'pwa-maskable-512x512.png',
            sizes: '512x512',
            type: 'image/png',
            purpose: 'maskable',
          },
        ],
      },
      devOptions: {
        enabled: true,
      },
    }),
  ],
});
