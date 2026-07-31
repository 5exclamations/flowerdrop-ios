#!/usr/bin/env bash
# Рендерит иконку приложения и знак для launch screen из SVG-исходников
# в docs/brand. Запускать после любой правки этих SVG.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BRAND="$ROOT/docs/brand"
ICONSET="$ROOT/FlowerDrop/Resources/Assets.xcassets/AppIcon.appiconset"
MARKSET="$ROOT/FlowerDrop/Resources/Assets.xcassets/LaunchMark.imageset"

if ! command -v rsvg-convert >/dev/null 2>&1; then
  echo "нужен rsvg-convert: brew install librsvg" >&2
  exit 1
fi

mkdir -p "$ICONSET" "$MARKSET"

# Иконка приложения. С Xcode 14 в каталоге достаточно одного 1024×1024 —
# все производные размеры система делает сама, поэтому набора PNG на каждый
# размер здесь нет намеренно.
rsvg-convert -w 1024 -h 1024 "$BRAND/icon.svg" -o "$ICONSET/icon-1024.png"
swift "$ROOT/scripts/flatten_png.swift" "$ICONSET/icon-1024.png"

# Знак для launch screen: прозрачный фон, три масштаба под @1x/@2x/@3x.
rsvg-convert -w 140 -h 140 "$BRAND/mark.svg" -o "$MARKSET/mark.png"
rsvg-convert -w 280 -h 280 "$BRAND/mark.svg" -o "$MARKSET/mark@2x.png"
rsvg-convert -w 420 -h 420 "$BRAND/mark.svg" -o "$MARKSET/mark@3x.png"

echo "иконка:"
sips -g pixelWidth -g pixelHeight -g hasAlpha "$ICONSET/icon-1024.png" | tail -3
echo "знак launch screen:"
for f in "$MARKSET"/mark*.png; do
  printf '  %s ' "$(basename "$f")"
  sips -g pixelWidth "$f" | tail -1 | tr -d '\n'
  echo
done
