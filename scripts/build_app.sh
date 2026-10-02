#!/usr/bin/env bash
set -euo pipefail

# Directory of the project root
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
APP_NAME="Caffeinate.app"
APP_DIR="${BUILD_DIR}/${APP_NAME}"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
PLUGINS_DIR="${CONTENTS_DIR}/PlugIns"
WIDGET_APPEX="${PLUGINS_DIR}/CaffeinateWidget.appex"

echo "☕ [1/5] Compiling Caffeinate main app in release mode..."
cd "${PROJECT_DIR}"
swift build -c release --product Caffeinate

BINARY_PATH="$(swift build -c release --show-bin-path)/Caffeinate"

if [ ! -f "${BINARY_PATH}" ]; then
    echo "❌ Error: Binary not found at ${BINARY_PATH}"
    exit 1
fi

echo "📦 [2/5] Assembling macOS Application Bundle (${APP_NAME})..."
rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"
mkdir -p "${PLUGINS_DIR}"

cp "${BINARY_PATH}" "${MACOS_DIR}/Caffeinate"
chmod +x "${MACOS_DIR}/Caffeinate"

# Copy Icon and Logo Assets
if [ -f "${PROJECT_DIR}/Resources/AppIcon.icns" ]; then
    cp "${PROJECT_DIR}/Resources/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
fi
if [ -f "${PROJECT_DIR}/Resources/app_logo.png" ]; then
    cp "${PROJECT_DIR}/Resources/app_logo.png" "${RESOURCES_DIR}/app_logo.png"
fi

echo "🧩 [3/5] Compiling macOS WidgetKit Extension (CaffeinateWidget.appex)..."
mkdir -p "${WIDGET_APPEX}/Contents/MacOS"
mkdir -p "${WIDGET_APPEX}/Contents/Resources"

swiftc -O -parse-as-library -target arm64-apple-macos14.0 \
  -framework WidgetKit -framework SwiftUI -framework AppKit \
  "${PROJECT_DIR}/Sources/CaffeinateWidget/CaffeinateWidget.swift" \
  -o "${WIDGET_APPEX}/Contents/MacOS/CaffeinateWidget"
chmod +x "${WIDGET_APPEX}/Contents/MacOS/CaffeinateWidget"

# Copy Icon to Widget Extension
if [ -f "${PROJECT_DIR}/Resources/AppIcon.icns" ]; then
    cp "${PROJECT_DIR}/Resources/AppIcon.icns" "${WIDGET_APPEX}/Contents/Resources/AppIcon.icns"
fi

cat << 'EOF' > "${WIDGET_APPEX}/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>CaffeinateWidget</string>
    <key>CFBundleIdentifier</key>
    <string>com.caffeinate.menubar.widget</string>
    <key>CFBundleName</key>
    <string>CaffeinateWidget</string>
    <key>CFBundleDisplayName</key>
    <string>Caffeinate</string>
    <key>CFBundlePackageType</key>
    <string>XPC!</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.widgetkit-extension</string>
    </dict>
</dict>
</plist>
EOF

echo "📝 [4/5] Generating App Info.plist (Icon & URL Scheme caffeinate://)..."
cat << 'EOF' > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Caffeinate</string>
    <key>CFBundleIdentifier</key>
    <string>com.caffeinate.menubar</string>
    <key>CFBundleName</key>
    <string>Caffeinate</string>
    <key>CFBundleDisplayName</key>
    <string>Caffeinate</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>com.caffeinate.menubar.url</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>caffeinate</string>
            </array>
        </dict>
    </array>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026. All rights reserved.</string>
</dict>
</plist>
EOF

echo "🔏 [5/5] Applying macOS ad-hoc code signature..."
codesign -s - --force --deep "${APP_DIR}"

echo "✨ Build complete!"
echo "--------------------------------------------------------"
echo "Application bundle created at:"
echo "  ${APP_DIR}"
echo ""
echo "To run the app (will open Popup Dashboard on launch):"
echo "  open \"${APP_DIR}\""
echo ""
echo "To install for daily use (with Widget available in macOS):"
echo "  cp -R \"${APP_DIR}\" /Applications/"
echo "--------------------------------------------------------"
