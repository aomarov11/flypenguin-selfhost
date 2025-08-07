#!/usr/bin/env bash
# Post-copy processing: assemble /public, sanitize filenames, localize fonts, strip trackers.
set -u
set -o pipefail

WORKDIR="$(pwd)"
MIRROR_DIR="$WORKDIR/mirror"
ROOT_DIR="$MIRROR_DIR/flypenguin.org"
PUBLIC_DIR="$WORKDIR/public"

echo "==> Assemble public/ from mirror"
mkdir -p "$PUBLIC_DIR"
if [ -d "$ROOT_DIR" ]; then
  # Prefer rsync if available
  if command -v rsync >/dev/null 2>&1; then
    rsync -a "$ROOT_DIR"/ "$PUBLIC_DIR"/ || echo "WARN: rsync copy failed; continuing"
  else
    (cd "$ROOT_DIR" && find . -type d -exec mkdir -p "$PUBLIC_DIR/{}" \;)
    (cd "$ROOT_DIR" && find . -type f -exec cp --parents "{}" "$PUBLIC_DIR/" \;)
  fi
else
  echo "WARN: $ROOT_DIR missing"
fi

echo "==> Ensure we have some HTML"
if ! find "$PUBLIC_DIR" -type f -name "*.html" | grep -q . ; then
  echo "ERROR: No HTML in public/"
  exit 1
fi

echo "==> Strip querystrings from filenames and fix references"
# 1) Rename files that contain '?' in the filename
mapfile -d '' FILES_WITH_Q < <(find "$PUBLIC_DIR" -type f -name '*\?*' -print0 || true)
for f in "${FILES_WITH_Q[@]:-}"; do
  # Compute new name without the querystring
  new="${f%\?*}"
  mkdir -p "$(dirname "$new")"
  if [ "$f" != "$new" ]; then
    # If a file already exists at target, overwrite
    mv -f "$f" "$new"
  fi
done

# 2) Rewrite references in HTML/CSS/JS that point to assets with ?version
#    Remove the ?... for common static extensions
find "$PUBLIC_DIR" -type f \( -name '*.html' -o -name '*.css' -o -name '*.js' \) -print0 | \
  xargs -0 sed -i -E 's/(\.(png|jpe?g|gif|svg|webp|ico|css|js))\?[^"'\'' )]+/\1/g' || true

echo "==> Localize Google Fonts if CSS present"
FONTS_CSS_OUT="$PUBLIC_DIR/assets/fonts/fonts.css"
: > "$FONTS_CSS_OUT"
if [ -d "$MIRROR_DIR/fonts.googleapis.com" ]; then
  # Concatenate CSS and rewrite gstatic URLs to local path
  find "$MIRROR_DIR/fonts.googleapis.com" -type f -print0 | \
    xargs -0 -I{} sh -c "sed -E 's|https://fonts\.gstatic\.com/|/assets/fonts/gstatic/|g' '{}' >> '$FONTS_CSS_OUT'; echo >> '$FONTS_CSS_OUT'" || true

  if [ -s "$FONTS_CSS_OUT" ]; then
    mkdir -p "$PUBLIC_DIR/assets/fonts/gstatic"
    if [ -d "$MIRROR_DIR/fonts.gstatic.com" ]; then
      if command -v rsync >/dev/null 2>&1; then
        rsync -a "$MIRROR_DIR/fonts.gstatic.com/" "$PUBLIC_DIR/assets/fonts/gstatic/" || true
      else
        (cd "$MIRROR_DIR/fonts.gstatic.com" && find . -type d -exec mkdir -p "$PUBLIC_DIR/assets/fonts/gstatic/{}" \;)
        (cd "$MIRROR_DIR/fonts.gstatic.com" && find . -type f -exec cp --parents "{}" "$PUBLIC_DIR/assets/fonts/gstatic/" \;)
      fi
    fi
    # Swap googleapis link tags to local fonts.css
    find "$PUBLIC_DIR" -type f -name '*.html' -print0 | \
      xargs -0 sed -i -E 's|<link[^>]+href="https://fonts\.googleapis\.com[^"]+"[^>]*>|<link rel="stylesheet" href="/assets/fonts/fonts.css">|g' || true
  fi
fi

echo "==> Remove Yandex Metrica beacons"
find "$PUBLIC_DIR" -type f -name '*.html' -print0 | \
  xargs -0 sed -i -E ':a;N;$!ba;s|<script[^<]*mc\.yandex\.ru[^<]*</script>||g' || true
find "$PUBLIC_DIR" -type f -name '*.html' -print0 | \
  xargs -0 sed -i -E 's|<noscript>.*mc\.yandex\.ru.*</noscript>||g' || true

echo "==> Ensure index.html exists"
if [ ! -f "$PUBLIC_DIR/index.html" ]; then
  CANDIDATE=$(find "$PUBLIC_DIR" -maxdepth 1 -type f -name "*.html" | head -n1 || true)
  [ -n "$CANDIDATE" ] && cp "$CANDIDATE" "$PUBLIC_DIR/index.html"
fi

if [ ! -f "$PUBLIC_DIR/index.html" ]; then
  echo "ERROR: No index.html to publish"
  exit 1
fi

echo "==> Postprocess complete"
exit 0
