#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo"

echo "checking repository checksums..."
sha256sum -c SHA256SUMS

image=prebuilt/Image-tb323fu-t65-personal.gz
echo "checking image compression..."
gzip -t "$image"

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
gzip -dc "$image" > "$tmp"
version=$(strings "$tmp" | grep -m1 'Linux version 7\.3\.0-tb323fu-t65-personal' || true)
[ -n "$version" ] || {
	echo "expected kernel version banner not found in $image" >&2
	exit 1
}
echo "$version"

upstream=$(find patches/upstream -maxdepth 1 -name '*.patch' | wc -l)
local=$(find patches/local -maxdepth 1 -name '*.patch' | wc -l)
[ "$upstream" -eq 210 ] || { echo "expected 210 upstream patches, found $upstream" >&2; exit 1; }
[ "$local" -eq 2 ] || { echo "expected 2 local patches, found $local" >&2; exit 1; }

for script in scripts/*.sh initramfs/helpers/back-to-android; do
	bash -n "$script"
done

if command -v tb323fu-ctl >/dev/null; then
	tb323fu-ctl kernel inspect "$image" 2>/dev/null || \
		echo "note: tb323fu-ctl could not inspect the image in this session"
fi
echo "verification passed"
