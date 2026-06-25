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

## 3. Find the target disk

```bash
lsblk
ls /dev/disk/by-id/
```

Make a note of the disk ID (e.g. `/dev/disk/by-id/nvme-...` for NVMe,
`/dev/vda` for a VM).

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

## 5. Point `_disko.nix` at the target disk

`_disko.nix` has the physical NVMe path by default. For a VM test, override
it with a `sed` one-liner (no permanent edits):

```bash
sed -i 's|nvme-PNY_CS3030_500GB_SSD_PNY48200266260101A28|vda|' \
  modules/hosts/marvielb/_disko.nix
```

## 6. Partition, format, and mount (disko only — no install)

```bash
sudo nix run 'github:nix-community/disko/latest#disko' -- \
  --mode format,mount \
  ./modules/hosts/marvielb/_disko.nix
```

This creates partitions, formats filesystems, and mounts at `/mnt`. No Nix
build happens — the tmpfs isn't touched.

## 7. Redirect `/nix` to the target disk

The live ISO's `/nix/store` is tmpfs (~3GB on 12GB RAM) — too small for a
full desktop build. Bind-mount the target's `/nix` subvolume over it:

```bash
sudo mount --bind /mnt/nix /nix
```

Now all build artifacts land on the NVMe (or virtual disk).

## 8. Install

```bash
sudo nixos-install --root /mnt --flake .#marvielb
```

This evaluates the flake and builds the closure on the target disk. Set the
root password when prompted.

## 9. Reboot

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
3. Follow steps 1–9 above
4. In step 5, override the disk with `sed -i 's|nvme-.*|vda|' modules/hosts/marvielb/_disko.nix`
5. In step 4, set `_hardware.nix` to `virtio` kernel modules (see example)

The only differences from bare metal are the disk device path (step 5) and
`_hardware.nix` contents (step 4). Everything else — boot loader, tmpfs root,
impermanence — is identical.

After confirming the VM works, restore `_disko.nix` to the NVMe path before
installing on bare metal:

```bash
git checkout modules/hosts/marvielb/_disko.nix
```
