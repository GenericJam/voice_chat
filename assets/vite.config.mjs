import { defineConfig } from 'vite'
import { phoenixVitePlugin } from 'phoenix_vite'

export default defineConfig({
  server: {
    port: 5173,
    strictPort: true,
    cors: { origin: "http://localhost:4000" },
  },
  optimizeDeps: {
    // https://vitejs.dev/guide/dep-pre-bundling#monorepos-and-linked-dependencies
    include: ["phoenix", "phoenix_html", "phoenix_live_view"],
  },
  build: {
    manifest: true,
    rollupOptions: {
      input: [
        "js/app.js",
        "css/app.css"
      ]
    },
    outDir: "../priv/static",
    emptyOutDir: false, // Don't delete existing static assets like images
  },
  // LV Colocated JS and Hooks
  // https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.ColocatedJS.html#module-internals
  resolve: {
    alias: {
      "@": ".",
      "phoenix-colocated": `${process.env.MIX_BUILD_PATH}/phoenix-colocated`,
    },
  },
  css: {
    postcss: './postcss.config.cjs',
  },
  plugins: [
    phoenixVitePlugin({
      pattern: /\.(ex|heex)$/
    })
  ]
});
