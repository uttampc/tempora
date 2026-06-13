2026-06-13T02:24:44.142Z	Initializing build environment...
2026-06-13T02:24:44.142Z	Initializing build environment...
2026-06-13T02:24:45.723Z	Success: Finished initializing build environment
2026-06-13T02:24:46.324Z	Cloning repository...
2026-06-13T02:24:47.861Z	Restoring from dependencies cache
2026-06-13T02:24:47.864Z	Restoring from build output cache
2026-06-13T02:24:47.868Z	Detected the following tools from environment: npm@10.9.2, nodejs@22.16.0
2026-06-13T02:24:47.975Z	Installing project dependencies: npm clean-install --progress=false
2026-06-13T02:24:52.024Z	npm warn deprecated source-map@0.8.0-beta.0: The work that was done in this beta branch won't be included in future versions
2026-06-13T02:24:52.639Z	npm warn deprecated glob@11.1.0: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me
2026-06-13T02:24:54.191Z	
2026-06-13T02:24:54.191Z	added 346 packages, and audited 347 packages in 6s
2026-06-13T02:24:54.194Z	
2026-06-13T02:24:54.195Z	102 packages are looking for funding
2026-06-13T02:24:54.195Z	  run `npm fund` for details
2026-06-13T02:24:54.195Z	
2026-06-13T02:24:54.195Z	found 0 vulnerabilities
2026-06-13T02:24:54.407Z	Executing user build command: npm run build
2026-06-13T02:24:54.698Z	
2026-06-13T02:24:54.698Z	> centerline@0.1.0 build
2026-06-13T02:24:54.698Z	> vite build
2026-06-13T02:24:54.698Z	
2026-06-13T02:24:55.021Z	vite v8.0.16 building client environment for production...
2026-06-13T02:24:55.137Z	
transforming...✓ 36 modules transformed.
2026-06-13T02:24:55.171Z	rendering chunks...
2026-06-13T02:24:55.212Z	computing gzip size...
2026-06-13T02:24:55.215Z	dist/registerSW.js                0.13 kB
2026-06-13T02:24:55.215Z	dist/manifest.webmanifest         0.64 kB
2026-06-13T02:24:55.215Z	dist/index.html                   1.18 kB │ gzip:  0.55 kB
2026-06-13T02:24:55.216Z	dist/assets/index-B2O6lZ2R.css   39.97 kB │ gzip:  6.87 kB
2026-06-13T02:24:55.216Z	dist/assets/index-zTNJM0qW.js   133.89 kB │ gzip: 38.56 kB
2026-06-13T02:24:55.216Z	
2026-06-13T02:24:55.216Z	✓ built in 194ms
2026-06-13T02:24:57.715Z	
2026-06-13T02:24:57.715Z	PWA v1.3.0
2026-06-13T02:24:57.716Z	mode      generateSW
2026-06-13T02:24:57.716Z	precache  11 entries (204.49 KiB)
2026-06-13T02:24:57.716Z	files generated
2026-06-13T02:24:57.716Z	  dist/sw.js
2026-06-13T02:24:57.716Z	  dist/workbox-9c191d2f.js
2026-06-13T02:24:57.845Z	Success: Build command completed
2026-06-13T02:24:57.996Z	Executing user deploy command: npx wrangler deploy
2026-06-13T02:24:59.533Z	npm warn exec The following package was not found and will be installed: wrangler@4.100.0
2026-06-13T02:25:10.143Z	
2026-06-13T02:25:10.143Z	 ⛅️ wrangler 4.100.0
2026-06-13T02:25:10.143Z	────────────────────
2026-06-13T02:25:10.163Z	
2026-06-13T02:25:10.163Z	Cloudflare collects anonymous telemetry about your usage of Wrangler. Learn more at https://github.com/cloudflare/workers-sdk/tree/main/packages/wrangler/telemetry.md
2026-06-13T02:25:10.350Z	
2026-06-13T02:25:10.420Z	✘ [ERROR] Error parsing file: /opt/buildhome/repo/vite.config.js
2026-06-13T02:25:10.421Z	
2026-06-13T02:25:10.421Z	
2026-06-13T02:25:10.446Z	If you think this is a bug then please create an issue at https://github.com/cloudflare/workers-sdk/issues/new/choose
2026-06-13T02:25:10.695Z	🪵  Logs were written to "/opt/buildhome/.config/.wrangler/logs/wrangler-2026-06-13_02-25-09_672.log"
2026-06-13T02:25:10.753Z	Failed: error occurred while running deploy command
