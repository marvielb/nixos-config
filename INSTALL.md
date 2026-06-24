# Live ISO Install

Boot the target machine with a NixOS 26.05 minimal ISO and run these steps.

## 1. Prepare the live environment

```bash
sudo -i
passwd                              # set root password (optional, for SSH)
systemctl start sshd                # optional — lets you SSH in from another machine
export NIX_CONFIG="experimental-features = nix-command flakes"
```

## 2. Clone this repo

```bash
nix-shell -p git
git clone <repo-url> /root/nixos-config
cd /root/nixos-config
```

## 3. Set the disk device

Find the target disk:

```bash
lsblk
ls /dev/disk/by-id/
```

`disko-install` will override the disk at runtime — no need to edit `_disko.nix`:

```
--disk main /dev/disk/by-id/<your-disk>
```

## 4. Generate hardware config

```bash
nixos-generate-config --root /mnt
```

Open the generated `/mnt/etc/nixos/hardware-configuration.nix` and copy the
`boot.initrd.availableKernelModules`, `boot.kernelModules`, and any
`hardware.cpu` / GPU sections into
`modules/hosts/<hostname>/_hardware.nix`. Do **not** copy `fileSystems` —
disko handles those.

<details>
<summary>Example: VM with virtio disk</summary>

```nix
# modules/hosts/marvielb/_hardware.nix
{ ... }: {
  boot.initrd.availableKernelModules = [ "virtio" "virtio_blk" "virtio_pci" ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
}
```

</details>

## 5. Partition, format, and install (single command)

```bash
sudo nix --extra-experimental-features "nix-command flakes" \
  run 'github:nix-community/disko/latest#disko-install' -- \
  --flake .#<hostname> \
  --disk main /dev/disk/by-id/<your-disk>
```

Replacing `<hostname>` with the target (e.g. `marvielb`, `practice`, `portfolio`).

This partitions the disk, formats filesystems, mounts at `/mnt`, copies the
config into the mount, and runs `nixos-install`. Set the root password when
prompted.

## 6. Reboot

```bash
reboot
```

Remove the ISO and boot into the new system.

## 7. Post-install: sops-nix bootstrap

From another machine that has this repo cloned, add the new machine's age key:

```bash
# Get the age public key from the new machine
ssh <user>@<ip> "ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub"

# Append it to .sops.yaml and rekey existing secrets
# (You can also follow just get-key if SSH hostname resolution is set up)
```

Then re-deploy to apply secrets:

```bash
just deploy <hostname>
```

## Testing in a VM first

If testing before bare metal:

1. Create a VM with UEFI (OVMF), 12GB+ RAM, one virtual disk
2. Boot the NixOS ISO in the VM
3. Follow steps 1–6 above, using the VM's disk ID (e.g. `scsi-0QEMU_QEMU_HARDDISK_drive-scsi0`)
4. Set `_hardware.nix` to the appropriate VM kernel modules (see example above)

The only differences from bare metal are the `--disk` device path and
`_hardware.nix` contents.
