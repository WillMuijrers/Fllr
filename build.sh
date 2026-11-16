#!/bin/bash
# Bouwt Fllr.app in ./build. Gebruik: ./build.sh [--run]
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

APP="build/Fllr.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp ".build/release/Fllr" "$APP/Contents/MacOS/Fllr"
cp "Resources/Info.plist" "$APP/Contents/Info.plist"
# Beeldmerk voor de menubalk; wordt als template-afbeelding geladen.
cp "Design/icon.svg" "$APP/Contents/Resources/MenuIcon.svg"
# Phosphor-iconen (MIT), inclusief licentietekst.
cp -R "Resources/Icons" "$APP/Contents/Resources/Icons"
codesign --force --sign - "$APP" >/dev/null

echo "Gebouwd: $APP"

if [[ "${1:-}" == "--run" ]]; then
    pkill -x Fllr 2>/dev/null || true
    open "$APP"
fi
