const CACHE_NAME = 'pwa-cache-v1';

/**
 * Danh sách URL cần cache offline.
 * ⚠️ Tuỳ chỉnh danh sách này cho project của bạn.
 */
const PRECACHE_URLS = [
  '/',
  '/index.html'
];

// --- Install: cache các file cần thiết ---
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(PRECACHE_URLS))
  );
  self.skipWaiting();
});

// --- Activate: xoá cache cũ ---
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

// --- Fetch: cache-first, fallback network ---
self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request).then(cached => cached || fetch(event.request))
  );
});
