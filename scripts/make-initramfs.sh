#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
kernel_build=
modules_root=
output=
squashfs_output=
aarch64_cc=${AARCH64_CC:-aarch64-linux-gnu-gcc}

usage()
{
	cat <<'EOF'
Usage: scripts/make-initramfs.sh --kernel-build DIR --modules-root DIR --output FILE

  --kernel-build DIR    kernel O= build directory
  --modules-root DIR    installed lib/modules/<release> directory with modules.dep
  --output FILE         output cpio.gz
  --squashfs-output FILE
                         also copy the generated module squashfs here
EOF
}

while [ $# -gt 0 ]; do
	case $1 in
		--kernel-build) kernel_build=${2:?}; shift ;;
		--modules-root) modules_root=${2:?}; shift ;;
		--output) output=${2:?}; shift ;;
		--squashfs-output) squashfs_output=${2:?}; shift ;;
		-h|--help) usage; exit 0 ;;
		*) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
	esac
	shift
done

[ -n "$kernel_build" ] && [ -n "$modules_root" ] && [ -n "$output" ] || {
	usage >&2
	exit 2
}
[ -s "$modules_root/modules.dep" ] || {
	echo "missing $modules_root/modules.dep; run depmod first" >&2
	exit 1
}
command -v mksquashfs >/dev/null || { echo "missing mksquashfs" >&2; exit 1; }

release=${modules_root##*/}
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT

gic=$kernel_build/usr/gen_init_cpio
if [ ! -x "$gic" ]; then
	echo "building gen_init_cpio from the kernel source..."
	gic=$stage/gen_init_cpio
	${HOSTCC:-cc} -O2 -o "$gic" "$kernel_build/usr/gen_init_cpio.c"
fi

echo "creating module squashfs for $release..."
mksquashfs "$modules_root" "$stage/modules.sqfs" \
	-comp xz -all-root -no-xattrs -noappend -quiet \
	-mkfs-time 0 -all-time 0 -processors 1 >/dev/null

echo "building static gpu-probe..."
"$aarch64_cc" -static -O2 -I"$kernel_build/usr/include" \
	-o "$stage/gpu-probe" "$repo/initramfs/gpu-probe.c"
strip="llvm-strip"
command -v "$strip" >/dev/null || strip="strip"
"$strip" --strip-debug "$stage/gpu-probe" 2>/dev/null || true

cat > "$stage/initramfs.list" <<EOF
dir /bin 0755 0 0
file /bin/busybox $repo/initramfs/third_party/busybox 0755 0 0
file /init $repo/initramfs/init 0755 0 0
file /bin/back-to-android $repo/initramfs/helpers/back-to-android 0755 0 0
file /bin/keyhold $repo/initramfs/helpers/keyhold 0755 0 0
file /bin/gpu-probe $stage/gpu-probe 0755 0 0
dir /etc 0755 0 0
dir /dev 0755 0 0
nod /dev/console 0600 0 0 c 5 1
file /font.psf $repo/initramfs/third_party/font.psf 0644 0 0
dir /proc 0755 0 0
dir /sys 0755 0 0
dir /sys/fs 0755 0 0
dir /sys/fs/pstore 0755 0 0
dir /lib 0755 0 0
dir /lib/modules 0755 0 0
dir /lib/modules/$release 0755 0 0
file /lib/modules/$release.sqfs $stage/modules.sqfs 0644 0 0
dir /lib/firmware 0755 0 0
file /lib/firmware/regulatory.db $repo/initramfs/third_party/regulatory.db 0644 0 0
file /lib/firmware/regulatory.db.p7s $repo/initramfs/third_party/regulatory.db.p7s 0644 0 0
EOF

mkdir -p "$(dirname "$output")"
"$gic" "$stage/initramfs.list" | gzip -9 -n > "$output"

if [ -n "$squashfs_output" ]; then
	cp "$stage/modules.sqfs" "$squashfs_output"
fi

echo "initramfs: $output ($(stat -c %s "$output") bytes)"
echo "modules: $(find "$modules_root" -name '*.ko' | wc -l)"
