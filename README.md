# megarac-boot-iso

Wrap an EFI binary in a bootable ISO and serve it to an **AMI MegaRAC** BMC as
an NFS-backed **virtual CD**.

Some servers have a BMC for power and serial but no network bootloader the test
harness can drive — the firmware won't PXE/HTTP-boot in a useful way, or you
have no control over DHCP where the board lives. This tool lets you boot such a
board off an arbitrary aarch64 (or x86) EFI binary — a standalone GRUB, a
distro's `grubaa64.efi`, an EFI shell — by handing the BMC an ISO over NFS and
having it present that ISO to the host as a CD-ROM.

It does two things:

1. Builds a UEFI-bootable ISO around the EFI binary (a FAT16 El Torito boot
   image holding `EFI/BOOT/BOOTAA64.EFI`), written into a directory your NFS
   server exports.
2. Points the BMC's remote (NFS) virtual media at that ISO and starts
   redirection, via the MegaRAC web API.

Powering the host on and selecting the CD as the boot device is **not** done
here — do that with IPMI (`ipmitool ... chassis bootdev cdrom options=efiboot`
then `chassis power on`) or the BMC UI, after this tool has attached the media.

## Requirements

`bash`, `curl`, `mtools`, `xorriso`, `coreutils`. On Debian:

```sh
apt-get install -y mtools xorriso curl
```

The BMC must have remote (NFS) media enabled, and the NFS server must export the
directory the ISO is written into, reachable from the BMC.

## Usage

```sh
megarac-boot-iso --efi grubaa64.efi \
    --bmc-host 192.168.0.10 \
    --nfs-server 192.168.0.2 \
    --nfs-path /srv/nfs/boot \
    --out-dir /srv/nfs/boot \
    --image-name lava-grub.iso
```

Credentials default to `admin`/`admin`; override with `--bmc-user`/`--bmc-pass`.
`--out-dir` is where the ISO is written and must be the same directory, on the
host, that `--nfs-path` names (they differ only when the writer sees it through
a bind mount — see LAVA below). Run `megarac-boot-iso --help` for all options.

### GRUB must carry its own serial config — use the bundled one

Use a **standalone** GRUB with the serial console baked into its own `(memdisk)`.
This repo ships one at [`grub/grubaa64.efi`](grub/grubaa64.efi) (built by
[`grub/build.sh`](grub/build.sh) from [`grub/grub.cfg`](grub/grub.cfg)); point
the job's download at its raw URL.

A **distro** `grubaa64.efi` (e.g. Debian's netboot one) does **not** work: its
prefix is a baked-in `(memdisk)`, so it ignores a `grub.cfg` placed on the ISO,
drops to the `grub>` shell on the *video* console, and never enables serial —
the harness sees nothing. Confirmed on the ThunderX2/AMI board this targets.

When wrapping an EFI that is *not* a standalone GRUB, the tool still writes a
small menu config to `/boot/grub/grub.cfg` and `/EFI/BOOT/grub.cfg` (serial
console, 10s timeout; `--console-speed` sets the baud, `--grub-cfg FILE`
overrides it) — but only a GRUB whose prefix points there will read it.

> **Board note:** the OS console (`console=ttyAMA0`) reaches the BMC's
> serial-over-LAN on its own, but GRUB cannot drive that UART on this board (no
> EFI Serial I/O Protocol, no PL011 driver in arm64-efi GRUB), so GRUB reaches
> SOL only via the firmware console. The firmware's BIOS **Console Redirection**
> must be **enabled** for the harness to interrupt GRUB over serial.

## Use under LAVA

The intended use is a `deploy: to: downloads` postprocess step. LAVA downloads
the EFI binary, bind-mounts the download directory into the postprocess
container, and exports `LAVA_DISPATCHER_IP`, `LAVA_JOB_ID` and
`LAVA_DISPATCHER_PREFIX`. The step can then be argument-free:

- `--nfs-server` / `--nfs-path` are derived from those `LAVA_*` variables;
- `--efi` defaults to the single `*.efi` just downloaded;
- `--image-name` defaults (or `$MEGARAC_IMAGE_NAME`);
- credentials default to `admin`/`admin`;
- `$BMC_HOST` identifies the board (see below).

See [`examples/lava-thunderx2.yaml`](examples/lava-thunderx2.yaml).

The BMC address is board-specific and the postprocess container cannot read the
LAVA device dictionary, so publish it in the device template's `dynamic_data`,
which LAVA exports into the step's environment as `$BMC_HOST`:

```jinja
{% if bmc_host is defined %}
dynamic_data:
  BMC_HOST: "{{ bmc_host }}"
{% endif %}
```

## License

MIT. See [LICENSE](LICENSE).
