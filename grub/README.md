# Bundled GRUB

`grubaa64.efi` is a standalone arm64 GRUB with [`grub.cfg`](grub.cfg) embedded in
its `(memdisk)`: it brings up the serial console and shows a 10-second,
interruptible menu wherever it is loaded from. Point a job's download at its raw
URL and let `megarac-boot-iso` wrap it.

Rebuild it with [`build.sh`](build.sh) (needs `grub-mkstandalone` for the
`arm64-efi` target — an arm64 host or container, as `grub-efi-arm64-bin` is not
in the amd64 archive).

Why not a distro `grubaa64.efi`: its prefix is a baked-in `(memdisk)`, so it
ignores a `grub.cfg` placed on the ISO and drops to the `grub>` shell — on the
video console, where the harness can't reach it.

Serial on the target board: the config uses the plain EFI `console`, not
`serial efi0`. That board has no EFI Serial I/O Protocol (so `serial efi0`
fails) and arm64-efi GRUB has no PL011 driver, so GRUB can only reach the BMC's
serial-over-LAN through the firmware console — i.e. the firmware's BIOS
**Console Redirection must be enabled** for the harness to drive GRUB. The OS
(`console=ttyAMA0`) reaches SOL on its own regardless; only GRUB needs this.
