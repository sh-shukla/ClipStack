#!/bin/zsh
# Builds ClipStack.app next to this script.
set -euo pipefail
cd "$(dirname "$0")"

APP="ClipStack.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

swiftc -O main.swift -o "$APP/Contents/MacOS/ClipStack" \
  -framework AppKit -framework Carbon -framework ServiceManagement
cp Info.plist "$APP/Contents/"
if [[ -f AppIcon.icns ]]; then
  mkdir -p "$APP/Contents/Resources"
  cp AppIcon.icns "$APP/Contents/Resources/"
else
  echo "note: AppIcon.icns missing — run 'swift make-icon.swift' first for the icon"
fi
codesign --force --sign - "$APP"

echo "Built $PWD/$APP"
echo "Open it with: open \"$PWD/$APP\""
