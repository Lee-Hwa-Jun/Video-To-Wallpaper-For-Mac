#!/usr/bin/env bash
# swift build 결과를 'Video Wallpaper.app' 번들로 묶습니다.
# 사용법: Scripts/build-app.sh [debug|release]   (기본값: release)
set -euo pipefail

cd "$(dirname "$0")/.."

CONFIG="${1:-release}"
APP_NAME="Video Wallpaper"
EXEC_NAME="VideoWallpaper"
OUT_DIR="build"
APP="$OUT_DIR/$APP_NAME.app"

echo "▶ swift build -c $CONFIG"
swift build -c "$CONFIG"

BIN_DIR="$(swift build -c "$CONFIG" --show-bin-path)"

echo "▶ 앱 번들 생성: $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/$EXEC_NAME" "$APP/Contents/MacOS/$EXEC_NAME"
cp Resources/Info.plist "$APP/Contents/Info.plist"
echo -n "APPL????" > "$APP/Contents/PkgInfo"

if [ -f Resources/AppIcon.icns ]; then
  cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
  /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$APP/Contents/Info.plist" >/dev/null 2>&1 || true
fi

if command -v codesign >/dev/null 2>&1; then
  echo "▶ ad-hoc 코드 서명"
  codesign --force --deep --sign - "$APP"
fi

echo "✅ 완료: $APP"
echo "   실행: open \"$APP\""
echo "   설치: cp -R \"$APP\" /Applications/"
