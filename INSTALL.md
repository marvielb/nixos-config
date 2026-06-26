# Install via nixos-anywhere

Builds on the **source machine** (e.g. Proxmox VM), ships the closure over
SSH. The target only needs a live ISO with SSH access — no local build needed.

## 1. Boot the target with NixOS minimal ISO

Boot the physical PC (or VM) with a NixOS 26.05 minimal ISO.

## 2. Prepare the live environment

```bash
sudo -i
passwd                              # set root password
systemctl start sshd                # enable SSH access
ip a                                # note the IP address
```

That's all the target needs. Everything else runs from your source machine.

## 3. From the source machine (Proxmox VM)

Ensure this repo is cloned and flakes are enabled:

```bash
git clone <repo-url> /path/to/config
cd /path/to/config
```

### For a VM test

Override the disk device before running:

```bash
sed -i 's|nvme-PNY_CS3030_500GB_SSD_PNY48200266260101A28|vda|' \
  modules/hosts/marvielb/_disko.nix
```

### Run nixos-anywhere

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#marvielb \
  --generate-hardware-config nixos-generate-config ./modules/hosts/marvielb/_hardware.nix \
  root@<target-ip>
```

This single command:

1. Evaluates `nixosConfigurations.marvielb` from the flake
2. Builds the closure on the source machine (plenty of space)
3. SSHs into the target live ISO
4. Runs disko to partition, format, and mount
5. Runs `nixos-generate-config` on the target, copies result to `_hardware.nix`
   (overwriting the stub committed in the repo)
6. Copies the closure and runs `nixos-install`
7. Prompts you to set the root password

## 4. Commit the generated hardware config

After the install finishes, `_hardware.nix` contains the full hardware config
(boot kernel modules, CPU microcode, etc.) for the actual machine. Commit it
from whatever machine has repo access:

```bash
git add modules/hosts/marvielb/_hardware.nix
git commit -m "add marvielb hardware config"
```

The `fileSystems` block in the generated file is harmless — disko overrides it.
No manual cherry-picking needed.

## 5. Reboot

Remove the ISO and boot into the new system.

## 6. Post-install: sops-nix bootstrap

From the source machine, add the new machine's age key:

```bash
ssh root@<target-ip> "ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub"
```

Append the key to `.sops.yaml` and rekey existing secrets, then redeploy:

```bash
git add -A && git commit -m "add marvielb sops key"
just deploy marvielb
```

## Testing in a VM first

1. Create a VM with UEFI (OVMF), 12GB+ RAM, one virtual disk
2. Boot NixOS ISO in the VM, follow step 2 above
3. On the source machine: `sed` override disk to `vda` (step 3), then run
   nixos-anywhere — this generates `_hardware.nix` with the correct `virtio`
   kernel modules for the VM automatically

After confirming the VM works, restore `_disko.nix`:

```bash
git checkout modules/hosts/marvielb/_disko.nix
```

Then install on bare metal — same command, just different IP and no `sed`.
