# Initramfs helpers

- `back-to-android` is the MIT shell source from tb323fu-linux
  `android/back-to-android`.
- `keyhold` is the static aarch64 helper built from tb323fu-linux
  `userspace/platform/src/keyhold.c` at commit
  `38f6c9adff49f6a1947142657af013c1090f9a9c`.

The local partial checkout of the upstream project does not contain the
`keyhold.c` blob, so the tested binary is retained here and its exact source
location is recorded in `NOTICE` and `SOURCE.md`.
