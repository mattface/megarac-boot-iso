# Bundled boot media

- **`lava-grub.iso`** — what jobs should use. A UEFI-bootable ISO wrapping
  `grubaa64.efi`; point a `deploy: to: flasher` image at its raw URL and let
  `megarac-boot-iso --iso` attach it. No build tools needed at run time.
- **`grubaa64.efi`** — a standalone arm64 GRUB with [`grub.cfg`](grub.cfg)
  embedded in its `(memdisk)`, so the console and a 30-second interruptible menu
  always run wherever it is loaded from.

Rebuild both with [`build.sh`](build.sh). It needs `grub-mkstandalone` for the
`arm64-efi` target (an arm64 host or container — `grub-efi-arm64-bin` is not in
the amd64 archive) plus `mtools` and `xorriso` for the ISO wrap.

## Why not a distro `grubaa64.efi`

Its prefix is a baked-in `(memdisk)`, so it ignores a `grub.cfg` placed on the
ISO and drops to the `grub>` shell — on the video console, where the harness
can't reach it. A standalone build carries its config with it.

## Serial on the target board

The config uses the plain EFI `console`, not `serial efi0`. That board has no
EFI Serial I/O Protocol (so `serial efi0` fails with ``terminal `serial' isn't
found``) and arm64-efi GRUB has no PL011 driver, so GRUB can only reach the
BMC's serial-over-LAN through the firmware console — i.e. the firmware's BIOS
**Console Redirection must be enabled** for the harness to drive GRUB. The OS
console (`console=ttyAMA0`) reaches SOL on its own regardless; only GRUB needs
this.
