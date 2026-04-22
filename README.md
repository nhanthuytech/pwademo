# 📱 PWA Install Kit

Module PWA tái sử dụng để thêm chức năng **"Add to Home Screen"** cho bất kỳ website nào.  
Hỗ trợ: **HTML thuần**, **React**, **Next.js**, **Vue**, **Angular**...

---

## 📁 Cấu trúc

```
pwademo/
├── pwa/                      ← COPY THƯ MỤC NÀY vào project của bạn
│   ├── pwa-manager.js        # Class xử lý cài đặt PWA
│   ├── sw.js                 # Service Worker (cache offline)
│   └── manifest.json         # Web App Manifest (template)
│
├── icons/                    ← Icon mẫu (thay bằng icon của bạn)
│   ├── icon-192.png
│   └── icon-512.png
│
├── index.html                # Demo landing page
├── style.css                 # Demo styles
└── vercel.json               # Deploy config
```

---

## 🚀 Tích hợp nhanh (3 bước)

### Bước 1: Copy file

Copy thư mục `pwa/` và `icons/` vào thư mục **public** (hoặc **static**) của project.

| Framework | Đặt vào đâu |
|-----------|-------------|
| HTML thuần | Thư mục gốc (`/`) |
| Next.js | `/public/pwa/` và `/public/icons/` |
| React (Vite) | `/public/pwa/` và `/public/icons/` |
| Vue | `/public/pwa/` và `/public/icons/` |

### Bước 2: Sửa manifest.json

Mở `pwa/manifest.json`, đổi thông tin app:

```json
{
  "name": "Tên App Của Bạn",
  "short_name": "App",
  "description": "Mô tả app",
  "start_url": "/",
  "theme_color": "#073042"
}
```

### Bước 3: Thêm code vào trang web

Chọn framework bạn đang dùng:

---

## 📝 Hướng dẫn theo Framework

### HTML thuần

Thêm vào `<head>`:
```html
<link rel="manifest" href="/pwa/manifest.json">
<meta name="theme-color" content="#073042">
```

Thêm trước `</body>`:
```html
<button id="install-btn" style="display:none">Tải App</button>

<script type="module">
  import { PWAManager } from '/pwa/pwa-manager.js';
  
  const pwa = new PWAManager('/pwa/sw.js');
  pwa.init();

  const btn = document.getElementById('install-btn');
  
  window.addEventListener('pwa:caninstall', () => {
    btn.style.display = 'block';
  });
  
  btn.onclick = () => pwa.install();
</script>
```

---

### React (Vite / CRA)

**1. Copy files:**
```
public/
├── pwa/
│   ├── pwa-manager.js
│   ├── sw.js
│   └── manifest.json
└── icons/
    ├── icon-192.png
    └── icon-512.png
```

**2. Thêm vào `index.html`:**
```html
<link rel="manifest" href="/pwa/manifest.json">
<meta name="theme-color" content="#073042">
```

**3. Tạo hook `usePWA.js`:**
```jsx
import { useState, useEffect, useRef } from 'react';

export function usePWA(swPath = '/pwa/sw.js') {
  const [canInstall, setCanInstall] = useState(false);
  const [isInstalled, setIsInstalled] = useState(false);
  const pwaRef = useRef(null);

  useEffect(() => {
    // Dynamic import vì PWAManager dùng window
    import('/pwa/pwa-manager.js').then(({ PWAManager }) => {
      const pwa = new PWAManager(swPath);
      pwa.init();
      pwaRef.current = pwa;

      const onCanInstall = () => setCanInstall(true);
      const onInstalled = () => {
        setCanInstall(false);
        setIsInstalled(true);
      };

      window.addEventListener('pwa:caninstall', onCanInstall);
      window.addEventListener('pwa:installed', onInstalled);

      return () => {
        window.removeEventListener('pwa:caninstall', onCanInstall);
        window.removeEventListener('pwa:installed', onInstalled);
        pwa.destroy();
      };
    });
  }, [swPath]);

  const install = async () => {
    if (pwaRef.current) {
      return await pwaRef.current.install();
    }
  };

  return { canInstall, isInstalled, install };
}
```

**4. Sử dụng trong component:**
```jsx
import { usePWA } from './usePWA';

function InstallButton() {
  const { canInstall, isInstalled, install } = usePWA();

  if (isInstalled) return <p>✅ Đã cài đặt!</p>;
  if (!canInstall) return null; // Ẩn nút khi chưa sẵn sàng

  return <button onClick={install}>📱 Tải App Ngay</button>;
}
```

---

### Next.js (App Router)

**1. Copy files vào `public/`** (giống React ở trên)

**2. Thêm manifest vào `app/layout.js`:**
```jsx
export const metadata = {
  manifest: '/pwa/manifest.json',
  themeColor: '#073042',
};
```

**3. Tạo `hooks/usePWA.js`** (giống code React ở trên, thêm `'use client'`):
```jsx
'use client';
import { useState, useEffect, useRef } from 'react';
// ... code giống phần React
```

**4. Tạo component `InstallButton.jsx`:**
```jsx
'use client';
import { usePWA } from '@/hooks/usePWA';

export default function InstallButton() {
  const { canInstall, isInstalled, install } = usePWA();

  if (isInstalled) return <p>✅ Đã cài đặt!</p>;
  if (!canInstall) return null;

  return <button onClick={install}>📱 Tải App</button>;
}
```

---

## ⚙️ API Reference

### `PWAManager`

| Method | Mô tả |
|--------|--------|
| `new PWAManager(swPath)` | Tạo instance, `swPath` mặc định là `/sw.js` |
| `.init()` | Đăng ký SW + lắng nghe sự kiện install |
| `.destroy()` | Dọn dẹp listeners (dùng trong React cleanup) |
| `.canInstall` | `true` nếu có thể cài đặt |
| `.install()` | Hiện prompt "Add to Home Screen". Trả về `{ outcome: 'accepted' | 'dismissed' | 'unavailable' }` |

### Events

| Event | Khi nào |
|-------|---------|
| `pwa:caninstall` | Trình duyệt cho phép cài đặt (hiện nút tải) |
| `pwa:installed` | User đã cài thành công |

---

## ⚠️ Lưu ý quan trọng

- **HTTPS bắt buộc**: PWA chỉ hoạt động trên HTTPS hoặc `localhost`
- **Chrome / Edge**: Hỗ trợ tốt nhất trên Android. Safari iOS dùng "Add to Home Screen" từ menu Share
- **`start_url` phải cùng domain**: Không thể set `start_url` sang domain khác
- **Icon PNG**: Luôn dùng PNG (không dùng SVG) cho icon trong manifest

---

## 🧪 Test trên máy

```bash
# Chạy local server
python3 -m http.server 3000

# Hoặc dùng npx
npx serve .
```

Mở `http://localhost:3000` trên Chrome → DevTools → Application → Manifest để kiểm tra.

---

## 📋 Checklist trước khi deploy

- [ ] Đã thay icon 192x192 và 512x512
- [ ] Đã sửa `name`, `short_name`, `description` trong manifest.json
- [ ] Đã sửa `theme_color` cho đúng brand color
- [ ] Đã thêm `<link rel="manifest">` vào HTML
- [ ] Website chạy trên HTTPS