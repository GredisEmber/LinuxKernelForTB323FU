# Building

`scripts/build.sh` reconstructs the kernel from the Linux v7.3 tarball, the
upstream board series, the two local patches, the recorded final config and the
aw882xx source in this repository.

## Requirements

- Linux x86-64 or aarch64 build host
- about 15 GiB free disk space and 16 GiB RAM recommended
- `clang` and `ld.lld` 23.1.4 (the tested toolchain)
- GNU make, bash, patch, flex, bison, bc, openssl, curl or wget
- `aarch64-linux-gnu-gcc` for the static initramfs helpers
- `mksquashfs` from squashfs-tools
- `depmod` from kmod
- gzip, tar, xz

The tested build used clang/LLD 23.1.4 with `LLVM=1` and generated 830 modules.

## Build

```bash
./scripts/build.sh
```

Useful options:

```bash
./scripts/build.sh --jobs 16
./scripts/build.sh --prepare-only     # fetch/extract/apply patches, then stop
./scripts/build.sh --no-initramfs     # kernel and modules only
```

Environment overrides:

```bash
WORK_DIR=/path/to/work JOBS=16 ./scripts/build.sh
BASE_TARBALL=/path/to/linux-7.3.tar.xz ./scripts/build.sh
```

The script:

1. downloads and SHA-256 verifies `linux-7.3.tar.xz` unless supplied;
2. extracts the tree and applies `patches/upstream/*.patch` followed by
   `patches/local/*.patch`;
3. copies the recorded final config and builds `Image`, `dtbs`, `modules` and
   installed headers;
4. installs the modules, builds `snd-soc-aw882xx.ko` into `extra/`, and runs
   `depmod`;
5. creates the deterministic module squashfs and initramfs;
6. injects that initramfs into `CONFIG_INITRAMFS_SOURCE`, relinks `Image`, and
   writes gzip output under `dist/`.

## Outputs

```text
dist/Image-tb323fu-t65-personal.gz
dist/initramfs-tb323fu-t65-personal.cpio.gz
dist/modules-tb323fu-t65-personal.sqfs
dist/BUILD-INFO.txt
dist/SHA256SUMS
```

The tracked `prebuilt/Image-tb323fu-t65-personal.gz` is the artifact built and
tested on 2026-11-25. A rebuild does not overwrite it.

## Initramfs

The prebuilt image has no vendor firmware. Its initramfs contains `init`, the
emergency helper, keyhold, gpu-probe, BusyBox, the font, wireless-regdb and the
shared module squashfs. The bootloader-provided firmware remains untouched and
the installed root supplies firmware files at runtime.

## Verify

```bash
./scripts/verify.sh
```

This checks all tracked checksums, the gzip stream, the embedded kernel version,
patch counts and executable script syntax.
