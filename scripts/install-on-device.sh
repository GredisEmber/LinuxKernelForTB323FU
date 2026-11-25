#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
image=${1:-$repo/prebuilt/Image-tb323fu-t65-personal.gz}
name=${2:-t65-personal}

[ -f "$image" ] || { echo "image not found: $image" >&2; exit 1; }
command -v tb323fu-ctl >/dev/null || { echo "tb323fu-ctl not found on this device" >&2; exit 1; }

if [ "$(id -u)" -ne 0 ]; then
	exec sudo "$0" "$@"
fi

echo "inspecting $image..."
tb323fu-ctl kernel inspect "$image"

echo "current kernel state:"
tb323fu-ctl kernel status || true

echo "keeping the currently running kernel as the known-good fallback..."
tb323fu-ctl kernel keep || echo "warning: current kernel could not be kept" >&2

echo "installing $image as trial '$name'..."
tb323fu-ctl kernel install-local "$image" --trial --name "$name"

echo
echo "installed. Reboot, wait for the system to start, then confirm it with:"
echo "  sudo tb323fu-ctl kernel keep"
echo "Rollback at any time with:"
echo "  sudo tb323fu-ctl kernel rollback --reboot"
