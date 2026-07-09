import { Hono } from "hono";

const pwa = new Hono();

const manifest = {
  name: "Pizzaria Campy",
  short_name: "Campy",
  description: "Pizzaria Campy - Arte em cada fatia. Peça sua pizza favorita!",
  start_url: "/api/public/app",
  display: "standalone",
  background_color: "#1a1a2e",
  theme_color: "#1a1a2e",
  orientation: "portrait",
  icons: [
    {
      src: "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNTEyIiBoZWlnaHQ9IjUxMiIgdmlld0JveD0iMCAwIDUxMiA1MTIiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PGNpcmNsZSBjeD0iMjU2IiBjeT0iMjU2IiByPSIyNTYiIGZpbGw9IiMxYTFhMmUiLz48Y2lyY2xlIGN4PSIyNTYiIGN5PSIyNTYiIHI9IjIzMCIgZmlsbD0iI2U5NDU2MCIvPjxwYXRoIGQ9Ik0yNTYgODBMMjAwIDM1MEgxMTJMMjU2IDgwWiIgZmlsbD0iI2Y1YTYyMyIvPjxwYXRoIGQ9Ik0yNTYgMTAwTDM4MCAzNDBIMTMyTDI1NiAxMDBaIiBmaWxsPSIjZmZmOGU3Ii8+PGNpcmNsZSBjeD0iMjIwIiBjeT0iMjQwIiByPSIyNSIgZmlsbD0iI2U5NDU2MCIvPjxjaXJjbGUgY3g9IjI5MCIgY3k9IjI2MCIgcj0iMjAiIGZpbGw9IiNlOTQ1NjAiLz48Y2lyY2xlIGN4PSIyNTAiIGN5PSIzMDAiIHI9IjE4IiBmaWxsPSIjZTk0NTYwIi8+PGVsbGlwc2UgY3g9IjIwMCIgY3k9IjI4MCIgcng9IjEyIiByeT0iOCIgZmlsbD0iIzI3YWU2MCIvPjxlbGxpcHNlIGN4PSIzMDAiIGN5PSIyMzAiIHJ4PSIxMCIgcnk9IjYiIGZpbGw9IiMzN2FlNjAiLz48ZWxsaXBzZSBjeD0iMjYwIiBjeT0iMzIwIiByeD0iOCIgcnk9IjUiIGZpbGw9IiMzN2FlNjAiLz48L3N2Zz4=",
      sizes: "512x512",
      type: "image/svg+xml",
      purpose: "any maskable"
    }
  ]
};

const serviceWorker = `
const CACHE_NAME = 'pizzaria-campy-v1';
const urlsToCache = ['/api/public/app', '/api/public/menu'];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(urlsToCache))
  );
  self.skipWaiting();
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.filter(name => name !== CACHE_NAME).map(name => caches.delete(name))
      );
    })
  );
  self.clients.claim();
});

self.addEventListener('fetch', event => {
  event.respondWith(
    fetch(event.request).then(response => {
      if (response.status === 200) {
        const responseClone = response.clone();
        caches.open(CACHE_NAME).then(cache => cache.put(event.request, responseClone));
      }
      return response;
    }).catch(() => caches.match(event.request))
  );
});
`;

pwa.get("/manifest.json", (c) => {
  c.header("Content-Type", "application/json");
  c.header("Cache-Control", "no-store");
  return c.json(manifest);
});

pwa.get("/sw.js", (c) => {
  c.header("Content-Type", "application/javascript");
  c.header("Cache-Control", "no-store");
  return c.body(serviceWorker);
});

export default pwa;
