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

### GRUB menu

A GRUB loaded from CD needs a config to show a menu. By default the tool embeds
a small one — a serial console and a 10-second timeout — so the test harness
can interrupt the menu and drop to the GRUB command line; if nobody interrupts,
it returns to firmware. Set the serial speed with `--console-speed`. The config
is written to `/boot/grub/grub.cfg` and `/EFI/BOOT/grub.cfg` (where a CD-loaded
GRUB looks). Pass `--grub-cfg FILE` to supply your own instead. A GRUB built as
a standalone binary with its config already embedded ignores these.

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
