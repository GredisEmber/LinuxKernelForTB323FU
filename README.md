# LinuxKernelForTB323FU

Lenovo Legion Tab Gen 5 / Legion Y700 5th Gen（TB323FU、SM8850
“kaanapali”、board `baldur`）的个人 Linux 内核构建。

当前预编译版本：

```text
7.3.0-tb323fu-t65-personal #2 SMP PREEMPT
构建时间：2026-11-25 16:41:57 CST
```

它基于 Linux v7.3 和 `tb323fu-linux` 的 `0001-0223` 补丁系列，再叠加本仓库
`patches/local/` 下的显示和 GPU/视频修复。镜像包含 initramfs 与共享模块
squashfs，共 830 个模块（829 个树内模块 + 树外 `snd-soc-aw882xx`）。

已在设备上验证：系统可启动，显示正常，花屏未复发；播放视频后两只 AW882xx
功放均报告 `start success`。

> **当前设备状态：`7.3.0-tb323fu-t65-personal` 已 Keep，状态为 good。**
> 以后再从本地文件安装 trial 内核时，仍需在启动成功后执行
> `sudo tb323fu-ctl kernel keep`；否则未确认的第三次启动可能回滚到已知 good
> 内核。

## 安装预编译镜像

把镜像和本仓库复制到平板，然后执行：

```bash
sha256sum -c SHA256SUMS

tb323fu-ctl kernel inspect prebuilt/Image-tb323fu-t65-personal.gz
tb323fu-ctl kernel status

# 先确认当前正在运行的内核，避免安装前丢失已知可用版本
sudo tb323fu-ctl kernel keep

sudo tb323fu-ctl kernel install-local \
  prebuilt/Image-tb323fu-t65-personal.gz \
  --trial --name t65-personal
```

重启并进入新内核后，再确认一次：

```bash
tb323fu-ctl kernel status
sudo tb323fu-ctl kernel keep
```

当前设备的 Hyprland 没有注册成 active logind session，polkit 会拒绝
`keep`、`install-local` 等 helper 操作，因此上面的特权命令统一使用 `sudo`。

回滚：

```bash
sudo tb323fu-ctl kernel rollback --reboot
```

## 仓库内容

| 路径 | 内容 |
|---|---|
| `prebuilt/` | 已验证的可安装 gzip Image 和构建信息 |
| `config/` | 最终 `.config`，以及上游板级配置片段 |
| `patches/upstream/` | `tb323fu-linux` 的 210 个 `0001-0223` 补丁 |
| `patches/local/` | DPU/DSI 防花屏与 Adreno/Iris 本地补丁 |
| `drivers/aw882xx/` | 树外 Awinic AW882xx 功放驱动源码 |
| `initramfs/` | 内置 initramfs 的 init、辅助程序与固定输入 |
| `scripts/build.sh` | 下载基线、应用补丁、编译内核/模块并打包 Image |
| `scripts/verify.sh` | 校验仓库文件、镜像 gzip 和内核版本 |
| `scripts/install-on-device.sh` | 在平板上检查并安装预编译镜像 |
| `SOURCE.md` | 精确源码组成、版本和第三方来源 |
| `BUILD.md` | 构建依赖和复现步骤 |

## 源码重建

```bash
./scripts/build.sh
```

默认工作目录是 `work/`，结果写入 `dist/`。需要约 15 GiB 空闲空间、clang/LLD
23.1.4、GNU make、flex、bison、bc、`squashfs-tools`、`kmod` 和
`aarch64-linux-gnu-gcc`。详细说明见 [BUILD.md](BUILD.md)。

## 范围与限制

- 这是个人构建，不是 `tb323fu-linux` 的官方发布。
- 预编译镜像不包含厂商固件；它们仍从已安装的 root 文件系统读取。
- 当前版本只验证了本次提交所记录的设备状态，不保证适用于其他硬件批次。
- 仓库不提交内核源码树或构建目录。基线 tarball、补丁、配置、驱动源码和构建
  脚本共同构成完整重建输入。

## 上游、许可与署名

项目基础来自 [joonhoekim/tb323fu-linux](https://github.com/joonhoekim/tb323fu-linux)，
本仓库记录的上游版本是 tag `kernel-t65`、commit
`38f6c9adff49f6a1947142657af013c1090f9a9c`。内核补丁、配置和
`aw882xx` 驱动按 GPL-2.0-only 分发；仓库脚本与本文档按 MIT 分发。完整署名、
许可证映射和第三方来源见 [NOTICE](NOTICE) 与 [SOURCE.md](SOURCE.md)。

本仓库与 Lenovo、Qualcomm 或 Valve 无隶属关系；相关名称只用于标识设备和软件。
