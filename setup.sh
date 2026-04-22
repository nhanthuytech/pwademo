#!/bin/bash
# ============================================================
# PWA Setup Script
# Sửa các biến bên dưới rồi chạy: ./setup.sh
# ============================================================

# ========== SỬA Ở ĐÂY ==========
APP_NAME="Android Developer Hub"
SHORT_NAME="Android Dev"
DESCRIPTION="Your hub for Android Development"
TARGET_URL="https://developer.android.com/"
THEME_COLOR="#073042"
ICON_PATH=""  # Đường dẫn icon PNG (512x512). Bỏ trống = giữ icon hiện tại.
# ================================

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║       📱 PWA Setup Script            ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""

# ============================================================
# 1. Cập nhật manifest.json
# ============================================================
cat > "$SCRIPT_DIR/pwa/manifest.json" <<EOF
{
  "name": "${APP_NAME}",
  "short_name": "${SHORT_NAME}",
  "description": "${DESCRIPTION}",
  "start_url": "/go.html",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "${THEME_COLOR}",
  "orientation": "portrait",
  "icons": [
    {
      "src": "/icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "/icons/icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "/icons/icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "maskable"
    }
  ]
}
EOF
echo -e "  ✅ pwa/manifest.json"

# ============================================================
# 2. Cập nhật go.html (redirect page)
# ============================================================
cat > "$SCRIPT_DIR/go.html" <<EOF
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="refresh" content="0;url=${TARGET_URL}">
    <title>Đang mở ứng dụng...</title>
    <style>
        body { margin:0; display:flex; justify-content:center; align-items:center; height:100vh; background:${THEME_COLOR}; color:#fff; font-family:sans-serif; }
        .spinner { width:40px; height:40px; border:4px solid rgba(255,255,255,0.2); border-top:4px solid #3DDC84; border-radius:50%; animation:spin .8s linear infinite; margin:0 auto 16px; }
        @keyframes spin { to { transform:rotate(360deg); } }
    </style>
</head>
<body>
    <div style="text-align:center">
        <div class="spinner"></div>
        <p>Đang mở ứng dụng...</p>
    </div>
</body>
</html>
EOF
echo -e "  ✅ go.html → ${TARGET_URL}"

# ============================================================
# 3. Xử lý icon (nếu có)
# ============================================================
if [ -n "$ICON_PATH" ] && [ -f "$ICON_PATH" ]; then
  mkdir -p "$SCRIPT_DIR/icons"
  
  # Copy icon gốc làm 512
  cp "$ICON_PATH" "$SCRIPT_DIR/icons/icon-512.png"
  
  # Resize 192x192 bằng sips (macOS built-in)
  cp "$ICON_PATH" "$SCRIPT_DIR/icons/icon-192.png"
  sips -z 192 192 "$SCRIPT_DIR/icons/icon-192.png" > /dev/null 2>&1
  
  echo -e "  ✅ icons/ (192x192 + 512x512)"
elif [ -n "$ICON_PATH" ]; then
  echo -e "  ⚠️  File icon không tồn tại: $ICON_PATH (giữ icon cũ)"
fi

# ============================================================
# 4. Tạo app.mobileconfig (iOS)
# ============================================================
ICON_FILE="$SCRIPT_DIR/icons/icon-192.png"
if [ -f "$ICON_FILE" ]; then
  ICON_B64=$(base64 -i "$ICON_FILE" | tr -d '\n\r')
else
  ICON_B64=""
fi

UUID1=$(uuidgen | tr '[:lower:]' '[:upper:]')
UUID2=$(uuidgen | tr '[:lower:]' '[:upper:]')

cat > "$SCRIPT_DIR/app.mobileconfig" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>PayloadContent</key>
    <array>
        <dict>
            <key>FullScreen</key>
            <true/>
            <key>Icon</key>
            <data>${ICON_B64}</data>
            <key>IsRemovable</key>
            <true/>
            <key>Label</key>
            <string>${SHORT_NAME}</string>
            <key>PayloadDisplayName</key>
            <string>${APP_NAME}</string>
            <key>PayloadIdentifier</key>
            <string>com.pwa.webclip.$(echo "$SHORT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')</string>
            <key>PayloadType</key>
            <string>com.apple.webClip.managed</string>
            <key>PayloadUUID</key>
            <string>${UUID1}</string>
            <key>PayloadVersion</key>
            <integer>1</integer>
            <key>URL</key>
            <string>${TARGET_URL}</string>
        </dict>
    </array>
    <key>PayloadDescription</key>
    <string>${DESCRIPTION}</string>
    <key>PayloadDisplayName</key>
    <string>${APP_NAME}</string>
    <key>PayloadIdentifier</key>
    <string>com.pwa.profile.$(echo "$SHORT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')</string>
    <key>PayloadOrganization</key>
    <string>${APP_NAME}</string>
    <key>PayloadType</key>
    <string>Configuration</string>
    <key>PayloadUUID</key>
    <string>${UUID2}</string>
    <key>PayloadVersion</key>
    <integer>1</integer>
</dict>
</plist>
EOF
echo -e "  ✅ app.mobileconfig (iOS)"

# ============================================================
# 5. Cập nhật index.html (landing page)
# ============================================================
# Cập nhật title
sed -i '' "s|<title>.*</title>|<title>${APP_NAME} | Tải App</title>|g" "$SCRIPT_DIR/index.html"

# Cập nhật theme-color
sed -i '' "s|content=\"#[0-9a-fA-F]*\"|content=\"${THEME_COLOR}\"|g" "$SCRIPT_DIR/index.html"

# Cập nhật h1
sed -i '' "s|<h1>.*</h1>|<h1>${APP_NAME}</h1>|g" "$SCRIPT_DIR/index.html"

# Cập nhật subtitle
sed -i '' "s|<p class=\"subtitle\">.*</p>|<p class=\"subtitle\">${DESCRIPTION}</p>|g" "$SCRIPT_DIR/index.html"

echo -e "  ✅ index.html (landing page)"

# ============================================================
# Done!
# ============================================================
echo ""
echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║        🎉 Hoàn tất cấu hình!        ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""
echo -e "  📱 App:    ${GREEN}${APP_NAME}${NC}"
echo -e "  🔗 URL:    ${GREEN}${TARGET_URL}${NC}"
echo -e "  🎨 Color:  ${GREEN}${THEME_COLOR}${NC}"
echo ""
echo -e "  ${YELLOW}Bước tiếp theo:${NC}"
echo -e "  1. git add -A && git commit -m 'Setup PWA for ${SHORT_NAME}' && git push"
echo -e "  2. Deploy lên Vercel và test trên Android/iOS"
echo ""
