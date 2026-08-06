---
name: nixos-manage-secrets
description: Manage sops-nix secrets in this repo — bootstrap a new machine, edit secrets, add machines, understand the age/SSH-key scheme
license: MIT
compatibility: opencode
metadata:
  scope: nixos-config
---

# Secret Management (sops-nix)

sops-nix with age encryption, using **SSH host keys** as age keys (no separate age key
to manage). Auto-generated SSH keys are the source of encryption — `ssh-to-age` derives
the age public key from them.

## Bootstrap a New Machine

Three commands, only on first deploy:

```bash
just deploy <host>            # 1. Deploy sops-nix module (no secrets yet)
just get-key <host>           # 2. Extract age pubkey → update .sops.yaml → rekey existing secrets
just edit-secret <path>       # 3. Create/edit encrypted secrets
git add -A && just deploy <host>  # Redeploy — secrets decrypted automatically
```

`just get-key` does three things:
1. SSHes into the target, runs `ssh-to-age` against its SSH host key
2. Appends the age key to `.sops.yaml` creation rules
3. Runs `sops updatekeys` on all existing `secrets.yaml` files to re-encrypt them for the new key

## Everyday Workflow

Once bootstrapped, all future secret changes are single-step:

```bash
just edit-secret modules/foo/secrets.yaml  # edit + re-encrypt
just deploy <host>                         # secrets decrypted at activation
```

## Adding a New Machine

Same as bootstrap: `just deploy <newhost>` → `just get-key <newhost>` → `just deploy <newhost>`.
The `get-key` step automatically rekeys all existing secrets so every machine can decrypt them.

## How Decryption Works

`sops-nix` reads `/etc/ssh/ssh_host_ed25519_key` at activation time via
`sops.age.sshKeyPaths`. This key matches the corresponding `age1...` public key
in `.sops.yaml`. No separate age key file is needed on the target machine.

## Secret File Convention

Per-module: `modules/<category>/<name>/secrets.yaml`
Shared: `.sops.yaml` at repo root defines which keys encrypt which paths.

## .sops.yaml Format

```yaml
creation_rules:
  - age: age1practice..., age1portfolio...
```

Single flat list — all keys can decrypt all secrets. Add new keys via `just get-key`.
