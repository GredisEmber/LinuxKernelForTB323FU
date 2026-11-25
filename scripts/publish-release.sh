#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
remote=GredisEmber/LinuxKernelForTB323FU
tag=${1:-kernel-t65-personal}
image=$repo/prebuilt/Image-tb323fu-t65-personal.gz
info=$repo/prebuilt/BUILD-INFO.txt

command -v gh >/dev/null || { echo "GitHub CLI 'gh' is required" >&2; exit 1; }
[ -f "$image" ] || { echo "missing $image" >&2; exit 1; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
sha256sum "$image" > "$tmp/SHA256SUMS.release"

if gh release view "$tag" --repo "$remote" >/dev/null 2>&1; then
	echo "release $tag exists; uploading assets with --clobber"
	gh release upload "$tag" "$image" "$info" "$tmp/SHA256SUMS.release" \
		--repo "$remote" --clobber
else
	gh release create "$tag" "$image" "$info" "$tmp/SHA256SUMS.release" \
		--repo "$remote" \
		--title "TB323FU kernel $tag" \
		--notes-file "$info"
fi
