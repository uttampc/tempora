$ cd holdon
$ cat vite.config.js                                                         
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
        name: 'HoldOn',                   
        short_name: 'HoldOn',                                                       
        description: 'Simple timers for poses, holds & reps.',                                                                                                          
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

$ cat package.json 
{
  "name": "holdon",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "devDependencies": {
    "vite": "^8.0.12",
    "vite-plugin-pwa": "^1.3.0"
  },
  "dependencies": {
    "idb": "^8.0.3",
    "sortablejs": "^1.15.7"
  }
}

$ find dist -maxdepth 2 -type f| sort
dist/apple-touch-icon.png
dist/assets/index-B2O6lZ2R.css
dist/assets/index-Broz70Pg.js
dist/favicon.svg
dist/icons.original.svg
dist/icon.svg
dist/index.html
dist/manifest.webmanifest
dist/registerSW.js
dist/sw.js
dist/workbox-9c191d2f.js

$ npm run build

> holdon@0.1.0 build
> vite build

vite v8.0.16 building client environment for production...
✓ 37 modules transformed.
computing gzip size...
dist/registerSW.js                0.13 kB
dist/manifest.webmanifest         0.63 kB
dist/index.html                   1.13 kB │ gzip:  0.52 kB
dist/assets/index-B2O6lZ2R.css   39.97 kB │ gzip:  6.87 kB
dist/assets/index-Broz70Pg.js   135.33 kB │ gzip: 39.12 kB

[INEFFECTIVE_DYNAMIC_IMPORT] src/components/modal.js is dynamically imported by src/views/player.js but also statically imported by src/components/activityPicker.js, src/components/dialog.js, src/components/exerciseEditor.js, src/components/historyModal.js, src/views/dataSection.js, dynamic import will not move module into another chunk.

✓ built in 123ms

PWA v1.3.0
mode      generateSW
precache  6 entries (171.33 KiB)
files generated
  dist/sw.js
  dist/workbox-9c191d2f.js

$ npm run preview -- --host

> holdon@0.1.0 preview
> vite preview --host

  ➜  Local:   https://localhost:4173/
  ➜  Network: https://192.168.1.100:4173/
  ➜  press h + enter to show help
