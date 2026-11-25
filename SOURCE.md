# Source composition

The prebuilt image was produced from the following inputs, in this order.

## 1. Linux base

| Item | Value |
|---|---|
| Release | Linux v7.3 |
| Commit | `c03c1a14507dfaf8b856c2608f9ac216021fc222` |
| Tarball | `linux-7.3.tar.xz` from `https://cdn.kernel.org/pub/linux/kernel/v7.x/` |
| Tarball SHA-256 | `87363c24f10e06321eb362765521094e94471f6bff8bce2d6b3e40f39f004953` |

## 2. Upstream board patch series

- Upstream repository: `https://github.com/joonhoekim/tb323fu-linux`
- Recorded tag: `kernel-t65`
- Recorded commit: `38f6c9adff49f6a1947142657af013c1090f9a9c`
- Path in upstream: `kernel/patches/`
- Files copied here: 210 patches, numbered `0001` through `0223` (number 0115
  is intentionally absent upstream)
- Destination: `patches/upstream/`
- Application order: bytewise filename order

The aggregate below is produced from inside `patches/upstream/` with:

```sh
sha256sum *.patch | sha256sum
```

Its value for the copied series is:

```text
35405f4b67654e1584465699a450badc84476a7f33d6a03fa6aa57bf256259ca
```

The per-file hashes are also covered by the repository-level `SHA256SUMS`.

`PROVENANCE.md` in the upstream repository remains the authoritative per-patch
origin and status record.

## 3. Local display and media changes

Applied after the upstream series:

| Patch | SHA-256 | Purpose |
|---|---|---|
| `patches/local/0001-dpu-dsi-bringup.patch` | `c0651422bd0d1d8d2e866121f94fbdf47c7446e1cc770741277b9e5aaf2bef23` | DPU/DSI bring-up: nonblocking commit wait, no DPU RC idle on DSI, linear formats, DSI timing and PLL SYSTEM_MUXES |
| `patches/local/0002-worktree-gmu-iris.patch` | `b5fc7cfffe4a8bfdf07312bba5838770c3a53ec654b8194131ad45313b43b394` | Adreno RPMh vote fixes, Iris safeguards and stable local version |

The local patches also disable SCM version suffixes in `scripts/setlocalversion`
so the kernel release and module vermagic remain stable.

## 4. Kernel configuration

- `config/config-tb323fu-t65-personal` is the final `.config` used for the
  tested build.
- `CONFIG_LOCALVERSION="-tb323fu-t65-personal"`.
- `CONFIG_INITRAMFS_SOURCE` is blank in the repository copy. `scripts/build.sh`
  injects the path of the initramfs it builds.
- The original board fragments are retained in `config/fragments/` for audit.

## 5. Out-of-tree audio driver

`drivers/aw882xx/` contains the Awinic AW882xx source from the upstream
tb323fu-linux project (which obtained it from AWINIC's vendor driver). It is
built against this exact kernel with `CONFIG_SND_SOC_AW882XX=m` and installed
under `extra/`.

## 6. Initramfs inputs

| Item | Source |
|---|---|
| `initramfs/init` | tb323fu-linux `kernel/initramfs/init`, MIT |
| `initramfs/gpu-probe.c` | tb323fu-linux `kernel/initramfs/gpu-probe.c`, GPL-2.0-only |
| `initramfs/helpers/back-to-android` | tb323fu-linux `android/back-to-android`, MIT; retained as source |
| `initramfs/helpers/keyhold` | static helper built from tb323fu-linux `userspace/platform/src/keyhold.c` at the recorded upstream commit; the partial local checkout does not contain that source blob |
| `initramfs/third_party/busybox` | Debian `busybox-static` 1:1.35.0-4+deb12u1+b1 |
| `initramfs/third_party/font.psf` | Terminus console font from the tested build environment |
| `initramfs/third_party/regulatory.db*` | wireless-regdb |

No proprietary vendor firmware is stored in this repository or embedded in the
prebuilt release image. The installed root filesystem supplies it at runtime.

## 7. Result

| Item | Value |
|---|---|
| Kernel release | `7.3.0-tb323fu-t65-personal` |
| Build number | `#2` |
| Image compression | gzip (`gzip -9 -n`) |
| Modules | 829 in-tree + `snd-soc-aw882xx.ko` = 830 |
| Verified | display, video playback, both AW882xx amplifiers |

Reproduction uses the same source inputs but is not promised to be bit-for-bit
identical: timestamps, host tool versions and generated metadata can differ.
