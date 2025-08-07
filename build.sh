#!/usr/bin/env bash
set -euo pipefail

ORIGIN="https://flypenguin.org"
WORKDIR="$(pwd)"
MIRROR_DIR="$WORKDIR/mirror"
PUBLIC_DIR="$WORKDIR/public"

echo "==> Cleaning previous build"
rm -rf "$MIRROR_DIR" "$PUBLIC_DIR"
mkdir -p "$MIRROR_DIR" "$PUBLIC_DIR/assets/fonts" "$PUBLIC_DIR/static"

echo "==> Mirroring site (HTML, images, CSS, JS, + Google Fonts); excluding analytics"
# --page-requisites pulls images/css/js used by pages
# --convert-links rewrites links for local browsing
# --adjust-extension saves .html for HTML
# --span-hosts allows grabbing fonts from google domains if referenced
# --domains limits mirrored hosts
# --reject-regex prevents downloading yandex metrica
wget \
  --recursive \
  --level=1 \
  --page-requisites \
  --adjust-extension \
  --convert-links \
  --no-parent \
  --span-hosts \
  --domains=flypenguin.org,fonts.googleapis.com,fonts.gstatic.com \
  --reject-regex='mc\.yandex\.ru' \
  --directory-prefix="$MIRROR_DIR" \
  "$ORIGIN"

# Location of mirrored root
ROOT_DIR="$MIRROR_DIR/flypenguin.org"

echo "==> Copying mirrored site to public/"
# Copy everything from site root (preserve structure)
rsync -a "$ROOT_DIR"/ "$PUBLIC_DIR"/

# Normalize: ensure we have a conventional assets dir
mkdir -p "$PUBLIC_DIR/assets/fonts"
mkdir -p "$PUBLIC_DIR/static/images"

# If Google Fonts CSS was downloaded, collate + rewrite to local
FONTS_CSS_OUT="$PUBLIC_DIR/assets/fonts/fonts.css"
: > "$FONTS_CSS_OUT"

if compgen -G "$MIRROR_DIR/fonts.googleapis.com/*" > /dev/null; then
  echo "==> Processing Google Fonts CSS to local"
  # Concatenate and rewrite gstatic references to local path
  for cssfile in "$MIRROR_DIR"/fonts.googleapis.com/*; do
    # Some files may be nested; handle both files and dirs
    if [ -f "$cssfile" ]; then
      sed -E 's|https://fonts\.gstatic\.com/|/assets/fonts/gstatic/|g' "$cssfile" >> "$FONTS_CSS_OUT"
      echo -e "\n" >> "$FONTS_CSS_OUT"
    fi
  done

  # Copy downloaded font binaries
  if [ -d "$MIRROR_DIR/fonts.gstatic.com" ]; then
    mkdir -p "$PUBLIC_DIR/assets/fonts/gstatic"
    rsync -a "$MIRROR_DIR/fonts.gstatic.com/" "$PUBLIC_DIR/assets/fonts/gstatic/"
  fi

  # Replace <link href="https://fonts.googleapis.com/..."> with local fonts.css
  if compgen -G "$PUBLIC_DIR/*.html" > /dev/null; then
    for html in "$PUBLIC_DIR"/*.html; do
      sed -i -E 's|<link[^>]+href="https://fonts\.googleapis\.com[^"]+"[^>]*>|<link rel="stylesheet" href="/assets/fonts/fonts.css">|g' "$html"
    done
  fi
fi

echo "==> Removing Yandex Metrica (scripts + noscript beacons)"
if compgen -G "$PUBLIC_DIR/*.html" > /dev/null; then
  for html in "$PUBLIC_DIR"/*.html; do
    # Remove <script ... mc.yandex.ru ...></script> blocks
    sed -i -E ':a;N;$!ba;s|<script[^<]*mc\.yandex\.ru[^<]*</script>||g' "$html"
    # Remove noscript tracking pixels
    sed -i -E 's|<noscript>.*mc\.yandex\.ru.*</noscript>||g' "$html"
  done
fi

echo "==> Ensuring images are local (already mirrored by wget)"
# Nothing special to do; wget already put /static/images/* under PUBLIC_DIR

echo "==> Build complete -> public/"
ls -la "$PUBLIC_DIR" || true
