#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="${ROOT_DIR}/resources/images/Logo_QR.png"
COMPACT="${ROOT_DIR}/resources/images/Logo_QR_icon.png"
SITE_ICON="${ROOT_DIR}/docs/logo.png"
WINDOWS_ICON="${ROOT_DIR}/deploy/windows/cloakqr.ico"

if command -v magick >/dev/null 2>&1; then
    IMAGE_TOOL=(magick)
elif command -v convert >/dev/null 2>&1; then
    IMAGE_TOOL=(convert)
else
    echo "Error: ImageMagick is required to generate icons." >&2
    exit 1
fi

if [[ ! -f "${SOURCE}" ]]; then
    echo "Error: canonical icon not found: ${SOURCE}" >&2
    exit 1
fi

geometry="$(identify -format '%wx%h' "${SOURCE}")"
if [[ "${geometry}" != "1024x1024" ]]; then
    echo "Error: canonical icon must be 1024x1024, got ${geometry}." >&2
    exit 1
fi

# Normalize transparent pixels to white, crop the visible mark, and restore 10% padding.
"${IMAGE_TOOL[@]}" "${SOURCE}" -background white -alpha remove -alpha off \
    -fuzz 3% -trim +repage -resize 820x820 \
    -gravity center -background white -extent 1024x1024 -strip "${COMPACT}"
cp "${COMPACT}" "${SITE_ICON}"

while read -r density size; do
    directory="${ROOT_DIR}/deploy/android/res/mipmap-${density}"
    mkdir -p "${directory}"
    "${IMAGE_TOOL[@]}" "${COMPACT}" -filter Lanczos -resize "${size}x${size}" -strip \
        "${directory}/ic_launcher.png"
    cp "${directory}/ic_launcher.png" "${directory}/ic_launcher_round.png"
done <<'SIZES'
mdpi 48
hdpi 72
xhdpi 96
xxhdpi 144
xxxhdpi 192
SIZES

"${IMAGE_TOOL[@]}" "${COMPACT}" \
    \( +clone -resize 16x16 \) \
    \( +clone -resize 24x24 \) \
    \( +clone -resize 32x32 \) \
    \( +clone -resize 48x48 \) \
    \( +clone -resize 64x64 \) \
    \( +clone -resize 128x128 \) \
    \( +clone -resize 256x256 \) \
    -delete 0 "${WINDOWS_ICON}"

echo "Generated app icons from ${SOURCE}"
