#!/bin/sh
# Rebuild the bundled boot media. Two variants, each a standalone arm64 GRUB
# with its grub.cfg embedded in its own (memdisk) so it runs wherever it is
# loaded from, wrapped as a UEFI-bootable ISO for a BMC to attach:
#
#   grubaa64.efi / lava-grub.iso
#       30s interruptible menu, for a harness that interrupts GRUB itself
#   grubaa64-nomenu.efi / lava-grub-nomenu.iso
#       no menu, drops straight to the grub> prompt (LAVA: needs_interrupt false)
#
# grub-mkstandalone needs the arm64-efi target (Debian/Ubuntu:
# grub-efi-arm64-bin grub-common) - run it on an arm64 host or container, since
# those packages are not in the amd64 archive. The ISO wrap needs mtools and
# xorriso.
set -eu
cd "$(dirname "$0")"

MODULES="efinet net tftp http gzio part_gpt efi_gop serial linux normal configfile echo reboot halt test sleep"

build() {
    cfg="$1"; efi="$2"; iso="$3"
    grub-mkstandalone -O arm64-efi -o "$efi" --modules="$MODULES" "boot/grub/grub.cfg=$cfg"
    echo "built $(pwd)/$efi"
    ../megarac-boot-iso --efi "$efi" --out-dir . --image-name "$iso" --build-only
}

build grub.cfg        grubaa64.efi        lava-grub.iso
build grub-nomenu.cfg grubaa64-nomenu.efi lava-grub-nomenu.iso
