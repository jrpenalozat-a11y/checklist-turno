/* Service worker mínimo para François Checklist.
   HTML: network-first (siempre lo más nuevo con conexión).
   Íconos/otros locales: cache-first. No cachea CDNs ni Supabase. */
const CACHE = "cf-v1";
const CORE = ["./manifest.json", "./icon-192.png", "./icon-512.png"];

self.addEventListener("install", e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(CORE)).then(() => self.skipWaiting()));
});
self.addEventListener("activate", e => {
  e.waitUntil(
    caches.keys().then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});
self.addEventListener("fetch", e => {
  const req = e.request;
  if(req.method !== "GET") return;
  const url = new URL(req.url);
  // solo gestionamos el mismo origen; CDNs y Supabase van directo a la red
  if(url.origin !== self.location.origin) return;

  // HTML / navegación: red primero, cae a caché si no hay conexión
  if(req.mode === "navigate" || (req.headers.get("accept") || "").includes("text/html")){
    e.respondWith(fetch(req).catch(() => caches.match("./index.html").then(r => r || caches.match("./"))));
    return;
  }
  // resto (íconos, manifest): caché primero
  e.respondWith(caches.match(req).then(r => r || fetch(req)));
});
