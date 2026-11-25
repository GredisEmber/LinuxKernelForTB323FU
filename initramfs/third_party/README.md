# Third-party initramfs inputs

| File | Provenance |
|---|---|
| `busybox` | Debian package `busybox-static` 1:1.35.0-4+deb12u1+b1, static aarch64, GPL-2.0 |
| `font.psf` | Terminus console font from console-setup, copied from the tested build environment |
| `regulatory.db` | wireless-regdb, ISC |
| `regulatory.db.p7s` | wireless-regdb signature, ISC |

BusyBox corresponding source is available from the Debian source package
`busybox` version `1:1.35.0-4+deb12u1`. The BusyBox build configuration is the
Debian `busybox-static` package configuration.

The helpers are included only to make the tested initramfs reproducible. The
native source for `gpu-probe` is in the parent directory; `init` and
`back-to-android` are retained as source as well.
