# megarac-boot-iso

Make an **AMI MegaRAC** BMC boot a host off an EFI binary, by serving it as an
NFS-backed **virtual CD**.

Some servers have a BMC for power and serial but no network bootloader the test
harness can drive — the firmware won't PXE/HTTP-boot in a useful way, or you
have no control over DHCP where the board lives. This tool lets you boot such a
board off an arbitrary aarch64 (or x86) EFI binary — a standalone GRUB, a
distro's `grubaa64.efi`, an EFI shell — by handing the BMC an ISO over NFS and
having it present that ISO to the host as a CD-ROM.

Powering the host on and selecting the CD as the boot device is **not** done
here — do that with IPMI (`ipmitool ... chassis bootdev cdrom options=efiboot`
then `chassis power on`) or the BMC UI, after this tool has attached the media.

## Modes

```sh
# attach an already-built ISO (needs only curl)
megarac-boot-iso --iso lava-grub.iso --bmc-host 192.168.0.10 --nfs-server 192.168.0.2

# build an ISO from an EFI binary and stop (needs mtools + xorriso)
megarac-boot-iso --efi grubaa64.efi --image-name lava-grub.iso --build-only

# build then attach
megarac-boot-iso --efi grubaa64.efi --bmc-host 192.168.0.10 --nfs-server 192.168.0.2
```

With `--iso`, the ISO's directory is what the BMC is pointed at and its basename
is the image name. Credentials default to `admin`/`admin` (`--bmc-user`/
`--bmc-pass`, or `$BMC_USER`/`$BMC_PASS`). Run `--help` for all options.

A prebuilt ISO ships in [`grub/lava-grub.iso`](grub/lava-grub.iso) — see
[`grub/README.md`](grub/README.md). Point a job at its raw URL and you never
need the build tools at run time.

## Requirements

`bash`, `curl`, `coreutils` — plus `mtools` and `xorriso` only when building.

The BMC must have remote (NFS) media enabled, and the NFS server must export the
directory holding the ISO, reachable from the BMC.

## Use under LAVA

Use a **`deploy: to: flasher`** action. LAVA downloads the ISO into the flasher
directory, which lives in the dispatcher's NFS-exported tree, and runs the
commands from the **device dictionary** there — so the per-device BMC address
comes from the device, and one device-type health check works unchanged on every
board. See [`examples/lava-thunderx2.yaml`](examples/lava-thunderx2.yaml).

In the job:

```yaml
- deploy:
    to: flasher
    images:
      iso:
        url: https://raw.githubusercontent.com/mattface/megarac-boot-iso/main/grub/lava-grub.iso
```

In the device dictionary (`{ISO}` is substituted by LAVA with the downloaded
filename; the flasher commands run with the flasher directory as `$PWD`, so the
NFS path is detected automatically):

```jinja
{% set flasher_deploy_commands = [
     'curl -fsSL -o /tmp/megarac-boot-iso https://raw.githubusercontent.com/mattface/megarac-boot-iso/main/megarac-boot-iso',
     'chmod +x /tmp/megarac-boot-iso',
     '/tmp/megarac-boot-iso --iso {ISO} --bmc-host ' ~ bmc_host ~ ' --nfs-server ' ~ nfs_server,
   ] %}
```

`--nfs-server` is needed here because LAVA only exports `$LAVA_DISPATCHER_IP`
to a `downloads` postprocess, not to flasher commands. It is the worker's LAN
address, a per-worker constant.

### Running inside a `downloads` postprocess instead

If you build the ISO at run time in a `to: downloads` postprocess container, the
working directory is a bind mount rather than the real path, so the tool derives
the host NFS path from `$LAVA_JOB_ID`/`$LAVA_DISPATCHER_PREFIX` and takes
`--nfs-server` from `$LAVA_DISPATCHER_IP`. That works, but the postprocess
cannot see any per-device value, so the BMC address has to be hardcoded in the
job — which is why the flasher route above is preferred.

## License

MIT. See [LICENSE](LICENSE).
