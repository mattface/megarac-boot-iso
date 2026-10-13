#!/bin/sh
# Rebuild the bundled boot media:
#   grubaa64.efi   a standalone arm64 GRUB with grub.cfg embedded in its
#                  (memdisk), so the console + interruptible menu always run
#   lava-grub.iso  that binary wrapped as a UEFI-bootable ISO, which is what
#                  jobs download and megarac-boot-iso attaches to a BMC
#
# grub-mkstandalone needs the arm64-efi target (Debian/Ubuntu:
# grub-efi-arm64-bin grub-common) - run it on an arm64 host or container, since
# those packages are not in the amd64 archive. The ISO wrap needs mtools and
# xorriso.
set -eu
cd "$(dirname "$0")"

grub-mkstandalone -O arm64-efi -o grubaa64.efi \
    --modules="efinet net tftp http gzio part_gpt efi_gop serial linux normal configfile echo reboot halt test sleep" \
    "boot/grub/grub.cfg=grub.cfg"
echo "built $(pwd)/grubaa64.efi"

../megarac-boot-iso --efi grubaa64.efi --out-dir . --image-name lava-grub.iso --build-only
