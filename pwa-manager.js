/**
 * PWAManager - A reusable class to handle PWA installation and Service Worker registration.
 * 
 * Usage in Vanilla HTML:
 *   import { PWAManager } from './pwa-manager.js';
 *   const pwa = new PWAManager();
 *   pwa.init();
 *   document.getElementById('download-btn').addEventListener('click', () => pwa.installPwa());
 * 
 * Usage in React/Next.js:
 *   useEffect(() => {
 *     const pwa = new PWAManager('/sw.js');
 *     pwa.init();
 *     
 *     const handleReady = () => setInstallReady(true);
 *     window.addEventListener('pwa-ready-to-install', handleReady);
 * 
 *     return () => {
 *       window.removeEventListener('pwa-ready-to-install', handleReady);
 *       pwa.cleanup();
 *     };
 *   }, []);
 */
export class PWAManager {
  constructor(serviceWorkerPath = '/sw.js') {
    this.serviceWorkerPath = serviceWorkerPath;
    this.deferredPrompt = null;
    
    this.handleBeforeInstallPrompt = this.handleBeforeInstallPrompt.bind(this);
    this.handleAppInstalled = this.handleAppInstalled.bind(this);
  }

  init() {
    this.registerServiceWorker();
    
    // Bắt sự kiện beforeinstallprompt để chặn prompt mặc định và lưu lại để gọi khi nhấn nút
    window.addEventListener('beforeinstallprompt', this.handleBeforeInstallPrompt);
    window.addEventListener('appinstalled', this.handleAppInstalled);
  }

  cleanup() {
    window.removeEventListener('beforeinstallprompt', this.handleBeforeInstallPrompt);
    window.removeEventListener('appinstalled', this.handleAppInstalled);
  }

  registerServiceWorker() {
    if ('serviceWorker' in navigator) {
      window.addEventListener('load', () => {
        navigator.serviceWorker.register(this.serviceWorkerPath)
          .then(registration => {
            console.log('Service Worker đăng ký thành công với scope: ', registration.scope);
          })
          .catch(error => {
            console.error('Đăng ký Service Worker thất bại: ', error);
          });
      });
    } else {
      console.warn('Trình duyệt không hỗ trợ Service Worker.');
    }
  }

  handleBeforeInstallPrompt(e) {
    // Ngăn trình duyệt tự động hiện prompt
    e.preventDefault();
    // Lưu lại event để trigger sau
    this.deferredPrompt = e;
    
    console.log('PWA đã sẵn sàng để cài đặt.');
    
    // Phát một custom event để UI (React, Nextjs, HTML) có thể lắng nghe và hiện nút "Tải App"
    window.dispatchEvent(new CustomEvent('pwa-ready-to-install'));
  }

  handleAppInstalled(evt) {
    console.log('PWA đã được cài đặt thành công.', evt);
    this.deferredPrompt = null;
    window.dispatchEvent(new CustomEvent('pwa-installed'));
  }

  async installPwa() {
    if (!this.deferredPrompt) {
      console.warn('Không thể cài đặt. Ứng dụng có thể đã được cài hoặc trình duyệt không hỗ trợ.');
      alert('Ứng dụng đã được cài đặt hoặc trình duyệt của bạn chưa sẵn sàng (thử trên Chrome/Edge/Android).');
      return false;
    }
    
    // Hiển thị prompt cài đặt
    this.deferredPrompt.prompt();
    
    // Chờ người dùng phản hồi (Chấp nhận / Từ chối)
    const { outcome } = await this.deferredPrompt.userChoice;
    console.log(`Người dùng đã chọn: ${outcome}`);
    
    // Sau khi dùng xong, set null
    this.deferredPrompt = null;
    
    return outcome === 'accepted';
  }
}
