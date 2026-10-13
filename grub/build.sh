#!/bin/sh
# Rebuild grubaa64.efi: a standalone arm64 GRUB with grub.cfg embedded in its
# (memdisk), so the serial console + interruptible menu always run.
#
# Needs grub-mkstandalone with the arm64-efi target (Debian/Ubuntu:
# grub-efi-arm64-bin grub-common) - run it on an arm64 host or an arm64
# container, since those packages are not in the amd64 archive.
set -eu
cd "$(dirname "$0")"

grub-mkstandalone -O arm64-efi -o grubaa64.efi \
    --modules="efinet net tftp http gzio part_gpt efi_gop serial linux normal configfile echo reboot halt test sleep" \
    "boot/grub/grub.cfg=grub.cfg"

echo "built $(pwd)/grubaa64.efi"
