/**
 * PWAManager - Module PWA tái sử dụng cho mọi framework.
 * 
 * Hỗ trợ: HTML thuần, React, Next.js, Vue, Angular...
 * 
 * === CÁCH DÙNG ===
 * 
 * 1. HTML thuần:
 *    <script type="module">
 *      import { PWAManager } from './pwa/pwa-manager.js';
 *      const pwa = new PWAManager();
 *      pwa.init();
 *      document.getElementById('btn').onclick = () => pwa.install();
 *    </script>
 * 
 * 2. React / Next.js:
 *    import { PWAManager } from '@/pwa/pwa-manager';
 *    // Xem README.md để biết chi tiết hook usePWA()
 */

export class PWAManager {
  constructor(swPath = '/sw.js') {
    this.swPath = swPath;
    this.deferredPrompt = null;
    this._onBeforeInstall = this._onBeforeInstall.bind(this);
    this._onAppInstalled = this._onAppInstalled.bind(this);
  }

  /** Khởi tạo: đăng ký Service Worker + lắng nghe sự kiện cài đặt */
  init() {
    this._registerSW();
    window.addEventListener('beforeinstallprompt', this._onBeforeInstall);
    window.addEventListener('appinstalled', this._onAppInstalled);
  }

  /** Dọn dẹp listener (dùng trong React useEffect cleanup) */
  destroy() {
    window.removeEventListener('beforeinstallprompt', this._onBeforeInstall);
    window.removeEventListener('appinstalled', this._onAppInstalled);
  }

  /** Kiểm tra PWA đã sẵn sàng cài đặt chưa */
  get canInstall() {
    return this.deferredPrompt !== null;
  }

  /** Gọi hàm này khi user bấm nút "Tải App" */
  async install() {
    if (!this.deferredPrompt) {
      // Trường hợp đã cài rồi hoặc trình duyệt không hỗ trợ
      return { outcome: 'unavailable' };
    }
    this.deferredPrompt.prompt();
    const { outcome } = await this.deferredPrompt.userChoice;
    this.deferredPrompt = null;
    return { outcome }; // 'accepted' hoặc 'dismissed'
  }

  // --- Private ---

  _registerSW() {
    if (!('serviceWorker' in navigator)) return;
    navigator.serviceWorker.register(this.swPath).catch(err => {
      console.warn('[PWA] SW registration failed:', err);
    });
  }

  _onBeforeInstall(e) {
    e.preventDefault();
    this.deferredPrompt = e;
    // Phát event để UI biết đã sẵn sàng cài đặt
    window.dispatchEvent(new CustomEvent('pwa:caninstall'));
  }

  _onAppInstalled() {
    this.deferredPrompt = null;
    window.dispatchEvent(new CustomEvent('pwa:installed'));
  }
}
