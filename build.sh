#!/usr/bin/env bash
set -u
set -o pipefail

ORIGIN="https://flypenguin.org"
WORKDIR="$(pwd)"
MIRROR_DIR="$WORKDIR/mirror"

echo "==> Cleaning"
rm -rf "$MIRROR_DIR" || true
mkdir -p "$MIRROR_DIR"

echo "==> wget mirror (errors tolerated)"
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
  "$ORIGIN" || { echo 'WARN: wget returned non-zero'; exit 8; }

exit 0
