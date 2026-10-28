# Debian 13 (trixie) nocloud arm64 boot files

The kernel and initrd here are taken, unmodified, out of Debian's own
official cloud image:

    https://cloud.debian.org/images/cloud/trixie/latest/debian-13-nocloud-arm64.tar.xz

    arch     arm64
    release  trixie (13)
    vendor   nocloud
    version  20261026-2643
    type     official

verified against that directory's `SHA512SUMS` before unpacking.

## Why mirror them

Debian publishes the cloud images only as partitioned disk images
(`.raw`, `.qcow2`, or a `.tar.xz` holding `disk.raw`). LAVA's `to: tftp`
deploy needs a standalone kernel and initrd, and will not open a disk
image to find them, so they are extracted once and kept here. The
upstream `latest/` directory also moves as new builds are published;
these files are pinned to the build above.

The `nocloud` variant is the one without cloud-init, so nothing waits
for a datasource that a lab network will not provide.

## How they were extracted

    tar xf debian-13-nocloud-arm64.tar.xz            # -> disk.raw (3 GB sparse, GPT)
    sfdisk -J disk.raw                               # p1 = Linux arm64 root, start 262144
    dd if=disk.raw of=root.img bs=512 skip=262144 count=6027264 conv=sparse
    debugfs -R "rdump /boot/vmlinuz-6.12.113+deb13-arm64 ." root.img
    debugfs -R "rdump /boot/initrd.img-6.12.113+deb13-arm64 ." root.img

No loop mount or root privileges needed - `debugfs` reads the ext4
partition directly.

## What they are

`vmlinuz-6.12.113+deb13-arm64` is an uncompressed arm64 `Image` with the
EFI stub (`ARMd` magic at offset 0x38), which is what GRUB's `linux`
command wants. `initrd.img-6.12.113+deb13-arm64` is the matching
initramfs-tools initrd built with `MODULES=most`, so it carries the NIC
and NFS modules needed to mount an NFS root, and they match the kernel
version exactly.

The rootfs from the same image is published as a release asset rather
than committed here, as it is too large for the repository.

## Login

`nocloud` has no cloud-init and `root` has no usable password hash
(`!unprovisioned`), with `/bin/bash` as its shell. The image ships
`bash`, so LAVA jobs using this rootfs should set `os: debian`, which
selects `/bin/bash` as `lava_test_sh_cmd`.
