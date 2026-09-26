import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { resolve } from "node:path";

// Two outputs: the dev/verification gallery (index.html) and `live.js`, the bundle the docs site
// (scripts/build_site.py) loads to mount live demos in its detail dialog.
export default defineConfig({
  base: "./",
  plugins: [react()],
  server: { port: 5173, strictPort: false, host: "127.0.0.1" },
  build: {
    outDir: "dist",
    emptyOutDir: true,
    rollupOptions: {
      // Vite drops entry exports in app builds; live.js must keep `mount` / `has` for the site.
      preserveEntrySignatures: "exports-only",
      input: {
        gallery: resolve(__dirname, "index.html"),
        live: resolve(__dirname, "src/live.tsx"),
      },
      output: {
        entryFileNames: (chunk) => (chunk.name === "live" ? "live.js" : "assets/[name]-[hash].js"),
      },
    },
  },
});
