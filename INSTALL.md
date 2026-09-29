# Install

Two ways to get this config onto a machine:

- **Method A — one machine** (recommended): everything from the target machine
  itself, driven by `just install-local`. No second computer needed.
- **Method B — two machines**: build on a source machine (e.g. Proxmox VM) and
  ship the closure over SSH with official `nixos-anywhere`.

Common to both: NixOS minimal ISO (26.05+), network, and this repo reachable
(`git clone <repo-url>` — also works from the target machine's ISO, so a
"second machine" is only needed if you already prefer building elsewhere).

---

# Method A — one machine (just install-local)

Does everything on the target machine only: clone → disk wipe → install →
hardware config commit → sops key bootstrap → push (optional). You still need
*something* to carry your personal age key and complete the `git push`
(phone browser or USB stick — a text file, nothing heavy).

## A1. Boot the NixOS minimal ISO

Connect to the network, then clone the repo from the ISO:

```bash
git clone <repo-url> /tmp/repo && cd /tmp/repo
```

## A2. Run the recipe

```bash
sudo -i
# minimal ISOs don't ship `just` (and nix-command is off by default) — use
# nix-shell, which enables flakes for that invocation only:
nix-shell -p just --run "just --justfile /tmp/repo/justfile install-local marvielb"
# the recipe installs the smallest closure (console → minimal, whichever
# the host provides); the full desktop comes with the post-install switch
```

The recipe walks you through:

1. Installs `git`, `sops`, `ssh-to-age` into the live environment
2. **Repo location** — it runs in-place from the clone you made in A1
   (no re-cloning; whatever revision you cloned is what gets installed)
3. **Root password** — one for this ISO session only; `nixos-anywhere`
   needs it to SSH into `root@localhost` (the ISO's root has no password
   out of the box, so Method A sets one internally and keeps the install
   self-contained)
3. **Personal key** — point at a *private* key file (USB stick is easiest).
   Your personal age key lives in `~/.config/sops/age/keys.txt` on your
   usual machine — carry **that file**, not an SSH key. (A `.pub` alone
   can't be used: rekeying has to decrypt first, and decryption needs
   private key material.) The recipe detects an `AGE-SECRET-KEY-…` file
   directly; a passphrase-protected SSH private key also works (converted
   with `ssh-to-age -private-key`). The derived key is stored at
   `/tmp/sops-age-keys.txt` (chmod 600, RAM only — never written to the
   installed system, wiped by the recipe's `rm` at the end).
   Used for `sops updatekeys`.
4. **LUKS passphrase** (only for `encrypt = true` hosts) — stored at
   `/tmp/luks.key`; the recipe temporarily injects
   `passwordFile = "/tmp/luks.key"` into
   `modules/hosts/<host>/default.nix` (uncommitted, ISO-only) so the install
   is fully unattended. Remove `passwordFile` from any committed copy.
5. Runs nixos-anywhere against `root@localhost` (disko wipes the disk) —
   partitioning and installing in two phases so the ISO's own `machine-id`
   can be transplanted first (systemd-boot's installer crashes on an empty
   one, and impermanence means the fresh root has none yet), preferring
   the smallest flake output (`-console` → `-minimal` → host, first that
   exists — a console-only closure fits the ISO's tmpfs RAM); the full
   desktop comes with the post-install switch below
6. Generates `_hardware.nix` from the actual machine
7. Appends the machine's age key to `.sops.yaml`, rekeys `secrets.yaml`
8. Commits `_hardware.nix` + `.sops.yaml`; copies the repo (with those
   changes) into the persisted `~/src/nixos-config` — after reboot the installed
   system already has its config at `~/src/nixos-config`, no re-clone — then offers
   to `git push`

### A3. Pushing from the ISO (optional; GitHub login)

The install environment has no stored credentials, so pushing there needs
one of these done once — all also doable later from the installed system:

**GitHub CLI device flow (easiest)**

```bash
nix-env -iA nixos.gh
gh auth login --web
gh auth setup-git              # wires the push helper into git
```

It prints a one-time code and `https://github.com/login/device` — open it
from any browser (your phone works), enter the code, done.

**Personal access token (HTTPS)** — create one with `Contents: Read and
write` at https://github.com/settings/personal-access-tokens, then:

```bash
git config --global credential.helper store
git push                       # asks once, cached afterwards
```

**Your SSH key** — needed anyway if the clone went over SSH
(`git@github.com:...`). Add the *matching* private key's public half to
GitHub → Settings → SSH and GPG keys and `cat` it into the ISO's
`~/.ssh/authorized_keys` from wherever you keep it; `ssh -T git@github.com`
verifies.

**No push possible?** Skip it — commits are already on the machine; rerun the
push from the installed system (below) or `git format-patch origin/master`
and carry the patch over.

## A4. Reboot

Remove the ISO, boot from disk. LUKS prompts at the console (interactive —
`passwordFile` was ISO-only). sops-nix decrypts with the machine's own key.

## A5. Post-install on the machine

```bash
cd ~/src/nixos-config     # persisted location, copied there by the recipe
nix-shell -p just --run "just --justfile justfile host=marvielb switch"
git push                 # if you skipped the push in the ISO
```

---

# Method B — two machines (nixos-anywhere from a source machine)

Builds on the **source machine**, ships the closure over SSH to the target
live ISO. The target only needs SSH access — no local build needed.

## B1. Boot the target with NixOS minimal ISO

```bash
sudo -i
passwd                              # set root password
systemctl start sshd                # enable SSH access
ip a                                # note the IP address
```

## B2. From the source machine

```bash
git clone <repo-url> /path/to/config
cd /path/to/config
```

### For a VM test

Override the disk device before running (edit `custom.disko.device` in
`modules/hosts/marvielb/default.nix`, e.g. change the `nvme-…` device to `vda`).

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

### Minimal-first install (recommended to avoid RAM pressure)

Each desktop host exposes a `-minimal` flake output that only pulls the lean
profile (`stylix`, `home-manager`, `gui_niri`, `gui_noctalia`) plus the host's
own hardware/auth/persistence — no browser, editor, or GUI-app blast radius.
Install that first (small closure, low RAM on both source and target), then
graduate to the full desktop with a normal switch:

```bash
# 1. Install the minimal system
nix run github:nix-community/nixos-anywhere -- \
  --flake .#marvielb-minimal \
  --generate-hardware-config nixos-generate-config ./modules/hosts/marvielb/_hardware.nix \
  root@<target-ip>

# 2. Boot, then switch to the full desktop
just host=marvielb switch
```

Same applies to `practice-minimal`. `portfolio` has no desktop profile, so no
minimal variant exists. No file edits are needed between steps — the host's
`custom.disko` device (and LUKS/swap settings) are identical for both variants.

### LUKS-encrypted install (marvielb)

`marvielb` sets `custom.disko.encrypt = true`, so the root partition is LUKS2.
Run the command from an interactive terminal — disko will **prompt for the LUKS
passphrase** during partitioning. At every boot, GRUB loads the kernel from the
unencrypted ESP (`/boot`) and the initrd prompts for the passphrase to unlock
`cryptroot`. If the interactive prompt doesn't forward over SSH, temporarily
set `passwordFile = "/tmp/luks.key"` in the luks block of
`modules/hosts/_disko.nix`, pre-seed that file on the target, install, then
remove it (boot becomes interactive again).

Swap is a separate unencrypted partition (8G for marvielb) outside the LUKS
container, with hibernation disabled (`resumeDevice = false`). Only the root
partition is encrypted.

## B3. Push hardware config + machine sops key

Commit from whatever machine has repo access (see A3 for how to log into
GitHub when that machine is not your usual one):

```bash
git add modules/hosts/marvielb/_hardware.nix
git commit -m "add marvielb hardware config"
```

The `fileSystems` block in the generated file is harmless — disko overrides
it. No manual cherry-picking needed.

## B4. Reboot

Remove the ISO and boot into the new system.

## B5. Post-install: sops-nix bootstrap

From any machine with repo or SSH access (the machine itself counts — clone
into persisted `~/src/nixos-config` and work there):

```bash
ssh root@<target-ip> "ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub"
```

Append the key to `.sops.yaml`, rekey the secrets
(`sops updatekeys secrets.yaml`), commit, then redeploy:

```bash
git add -A && git commit -m "add marvielb sops key"
just deploy marvielb
```

## Testing in a VM first

1. Create a VM with UEFI (OVMF), 12GB+ RAM, one virtual disk
2. Boot NixOS ISO in the VM, follow A1/A2 above (with disk overridden to `vda`,
   step B2), then run nixos-anywhere — this generates `_hardware.nix` with the
   correct `virtio` kernel modules for the VM automatically
3. After confirming the VM works, restore `custom.disko.device`:

```bash
git checkout modules/hosts/marvielb/default.nix
```

Then install on bare metal — same command, just different IP and no device edit.

---

# Why only *your* age key is needed for rekeying

`sops updatekeys` decrypts with **your** personal key and re-encrypts with the
full recipient list from `.sops.yaml` (now including the new machine's
*public* age key, derived from its host SSH key). The new machine only needs
its *private* key at first boot to decrypt the deployed secrets — the key
already exists on disk (made during install, converted via `ssh-to-age`).
