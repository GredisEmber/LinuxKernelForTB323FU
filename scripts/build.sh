#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
work=${WORK_DIR:-$repo/work}
src=$work/linux-7.3
build=$work/build
modroot=$work/modinst
dist=$work/dist
jobs=${JOBS:-$(nproc)}
base_url=https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-7.3.tar.xz
base_sha=87363c24f10e06321eb362765521094e94471f6bff8bce2d6b3e40f39f004953
base_tar=${BASE_TARBALL:-$work/linux-7.3.tar.xz}
prepare_only=0
with_initramfs=1

usage()
{
	cat <<'EOF'
Usage: scripts/build.sh [options]

  --prepare-only   download, extract and patch the source, then stop
  --no-initramfs   build only Image and modules; do not package an initramfs
  --jobs N         parallel make jobs (default: nproc)
  -h, --help       show this help

Environment:
  WORK_DIR=/path       build workspace (default: ./work)
  BASE_TARBALL=/path   use a local linux-7.3.tar.xz
  JOBS=N               parallel make jobs
EOF
}

while [ $# -gt 0 ]; do
	case $1 in
		--prepare-only) prepare_only=1 ;;
		--no-initramfs) with_initramfs=0 ;;
		--jobs) jobs=${2:?missing job count}; shift ;;
		-h|--help) usage; exit 0 ;;
		*) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
	esac
	shift
done

need()
{
	command -v "$1" >/dev/null || {
		echo "missing required command: $1" >&2
		exit 1
	}
}

for c in make patch tar xz gzip; do need "$c"; done

mkdir -p "$work"

if [ ! -f "$base_tar" ]; then
	echo "downloading Linux v7.3 tarball..."
	if command -v curl >/dev/null; then
		curl -fL --retry 3 -o "$base_tar.part" "$base_url"
	elif command -v wget >/dev/null; then
		wget -O "$base_tar.part" "$base_url"
	else
		echo "curl or wget is required to download $base_url" >&2
		exit 1
	fi
	mv "$base_tar.part" "$base_tar"
fi

echo "$base_sha  $base_tar" | sha256sum -c -

if [ ! -d "$src" ]; then
	echo "extracting Linux v7.3..."
	tar -xJf "$base_tar" -C "$work"
fi

marker=$src/.tb323fu-patched
if [ ! -e "$marker" ]; then
	echo "applying upstream board patches..."
	for p in "$repo"/patches/upstream/*.patch; do
		echo "  ${p##*/}"
		patch --batch --forward --silent -p1 -d "$src" < "$p"
	done

	echo "applying local patches..."
	for p in "$repo"/patches/local/*.patch; do
		echo "  ${p##*/}"
		patch --batch --forward --silent -p1 -d "$src" < "$p"
	done

	touch "$marker"
else
	echo "source tree is already patched; reusing $src"
fi

if [ "$prepare_only" -eq 1 ]; then
	echo "prepare complete: $src"
	exit 0
fi

for c in clang ld.lld flex bison bc depmod mksquashfs; do need "$c"; done
if ! command -v aarch64-linux-gnu-gcc >/dev/null; then
	echo "missing aarch64-linux-gnu-gcc (needed for static initramfs helpers)" >&2
	exit 1
fi

mkdir -p "$build" "$dist"
cp "$repo/config/config-tb323fu-t65-personal" "$build/.config"
"$src/scripts/config" --file "$build/.config" --set-str INITRAMFS_SOURCE ""

make_kernel()
{
	make -C "$src" O="$build" ARCH=arm64 LLVM=1 "$@"
}

echo "configuring kernel..."
make_kernel olddefconfig

echo "building Image, dtbs and modules with $jobs jobs..."
make_kernel -j"$jobs" Image dtbs modules
make_kernel headers_install

release=$(make_kernel -s kernelrelease)
echo "kernel release: $release"

echo "installing in-tree modules..."
rm -rf "$modroot"
make_kernel INSTALL_MOD_PATH="$modroot" INSTALL_MOD_STRIP=1 modules_install

echo "building the out-of-tree AW882xx module..."
make_kernel LOCALVERSION= M="$repo/drivers/aw882xx" CONFIG_SND_SOC_AW882XX=m \
	INSTALL_MOD_PATH="$modroot" INSTALL_MOD_DIR=extra modules modules_install

modules_dir=$modroot/lib/modules/$release
rm -f "$modules_dir/build" "$modules_dir/source"
depmod -b "$modroot" "$release"

mod_count=$(find "$modules_dir" -name '*.ko' | wc -l)
echo "installed modules: $mod_count"
if [ "$mod_count" -lt 830 ]; then
	echo "warning: expected at least 830 modules, found $mod_count" >&2
fi

if [ "$with_initramfs" -eq 1 ]; then
	echo "packaging the initramfs..."
	"$repo/scripts/make-initramfs.sh" \
		--kernel-build "$build" \
		--modules-root "$modules_dir" \
		--output "$dist/initramfs-$release.cpio.gz" \
		--squashfs-output "$dist/modules-${release#7.3.0-tb323fu-}.sqfs"

	"$src/scripts/config" --file "$build/.config" \
		--set-str INITRAMFS_SOURCE "$dist/initramfs-$release.cpio.gz"
	make_kernel olddefconfig
	echo "relinking Image with the built-in initramfs..."
	make_kernel -j"$jobs" Image
fi

gzip -9 -n -c "$build/arch/arm64/boot/Image" > "$dist/Image-tb323fu-t65-personal.gz"

cat > "$dist/BUILD-INFO.txt" <<EOF
tb323fu t65 personal kernel
===========================

Release:        $release
Base:           Linux v7.3, c03c1a14507dfaf8b856c2608f9ac216021fc222
Upstream:       tb323fu-linux kernel-t65, 38f6c9adff49f6a1947142657af013c1090f9a9c
Patches:        210 upstream (0001-0223) + 2 local
Toolchain:      clang/LLD $(clang --version | head -1 | sed 's/.*version //')
Config:         config/config-tb323fu-t65-personal
Modules:        $mod_count (includes snd-soc-aw882xx in extra/)
Initramfs:      $with_initramfs (embedded in Image when enabled)

Artifact:       Image-tb323fu-t65-personal.gz
Built:          $(date -u +%Y-%m-%dT%H:%M:%SZ)

Install locally on the tablet:
  tb323fu-ctl kernel inspect Image-tb323fu-t65-personal.gz
  sudo tb323fu-ctl kernel keep
  sudo tb323fu-ctl kernel install-local Image-tb323fu-t65-personal.gz --trial --name t65-personal

After the first successful boot:
  sudo tb323fu-ctl kernel keep
EOF

(
	cd "$dist"
	sha256sum Image-tb323fu-t65-personal.gz BUILD-INFO.txt > SHA256SUMS
	if [ "$with_initramfs" -eq 1 ]; then
		sha256sum "initramfs-$release.cpio.gz" >> SHA256SUMS
	fi
	for f in modules-*.sqfs; do
		[ -f "$f" ] && sha256sum "$f" >> SHA256SUMS
	done
)

echo
echo "build complete:"
ls -lh "$dist"/Image-tb323fu-t65-personal.gz "$dist"/BUILD-INFO.txt
echo "sha256: $(sha256sum "$dist/Image-tb323fu-t65-personal.gz" | cut -d' ' -f1)"
