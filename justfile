# NixOS Config — Build helpers

host := "practice"

# Build the system (dry run, doesn't switch)
build:
    nh os build . -H {{host}}

# Build and activate
switch:
    nh os switch . -H {{host}}

# Deploy to a remote host
deploy host=host:
    nh os switch . -H {{host}} --target-host {{host}}@{{host}}.box

deploy-boot host=host:
    nh os boot . -H {{host}} --target-host {{host}}@{{host}}.box

deploy-vm:
    nh os switch . -H  marvielb --target-host marvielb@192.168.122.32

deploy-vm-boot:
    nh os boot . -H marvielb --target-host marvielb@192.168.122.32

# One-time bootstrap: extract age key from a deployed machine and add to .sops.yaml
get-key host=host:
    #!/usr/bin/env bash
    set -euo pipefail

    AGE_KEY=$(ssh {{host}}@{{host}}.box "ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub")
    echo "→ Age key for {{host}}: $AGE_KEY"

    if [ ! -f .sops.yaml ]; then
        echo "creation_rules:" > .sops.yaml
        echo "  - age: $AGE_KEY" >> .sops.yaml
        echo "→ Created .sops.yaml"
    elif grep -qF "$AGE_KEY" .sops.yaml; then
        echo "→ Key already in .sops.yaml — nothing to do"
        exit 0
    else
        sed -i "1,/^  - age:/{/^  - age:/s/$/, $AGE_KEY/}" .sops.yaml
        echo "→ Added key to .sops.yaml"
    fi

    # Re-encrypt all existing sops secrets with the new key set
    for f in $(find . -name 'secrets.yaml' -type f 2>/dev/null || true); do
        if grep -q '^sops:' "$f" 2>/dev/null; then
            echo "→ Rekeying: $f"
            nix run nixpkgs#sops -- updatekeys "$f" --yes 2>/dev/null || true
        fi
    done

    git add .sops.yaml
    echo "→ Done. Commit and redeploy:"
    echo "    git commit -m \"add {{host}} sops key\""
    echo "    just deploy {{host}}"

# Create or edit an encrypted secret (reads .sops.yaml automatically)
edit-secret path:
    nix run nixpkgs#sops -- {{path}}

# One-machine install: run ON the target machine (NixOS minimal ISO, root, network up).
# Clones the repo, prompts for your personal age key (RAM-only) and LUKS passphrase,
# installs via loopback SSH, inventories the machine key and rekeys secrets.
# Usage: just install-local marvielb          (or marvielb-minimal for low-RAM machines)
# Bootstrapping on the ISO (which ships no just): nix-shell -p just --run \
#   "just --justfile /tmp/repo/justfile install-local <host>"
install-local host=host device="":
    #!/usr/bin/env bash
    set -euo pipefail

    # ISO defaults have nix-command/flakes off; enable for this recipe only.
    # Pre-trusting the flake's cachix settings avoids an interactive prompt
    # under nix-shell (which has no stdin left for it).
    export NIX_CONFIG="experimental-features = nix-command flakes
    extra-substituters = https://noctalia.cachix.org
    extra-trusted-public-keys = noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="

    cd /tmp
    echo "→ Installing tools into the live environment (tmpfs)"
    for pkg in git sops ssh-to-age; do
      command -v "$pkg" >/dev/null 2>&1 || nix-env -iA "nixos.$pkg"
    done

    # run in-place: the repo is wherever the justfile lives.
    # nix refuses to eval a git tree owned by another user, so claim it.
    # Also drop leftovers from previous runs: the recipe injects the LUKS
    # passwordFile and _hardware.nix gets regenerated — start clean so a
    # retried run can't stack a duplicate passwordFile and break eval.
    cd "{{justfile_directory()}}"
    chown -R "$(id -u):$(id -g)" .
    git checkout HEAD -- "modules/hosts/{{host}}/default.nix" "modules/hosts/{{host}}/_hardware.nix"
    git add -A
    read -rsp "→ Root password for this ISO session (nixos-anywhere SSHes to root@localhost): " ROOT_PW; echo
    printf 'root:%s\n' "$ROOT_PW" | chpasswd
    unset ROOT_PW
    systemctl start sshd 2>&1 || true

    echo "→ Personal key for sops decryption (rekeying needs a PRIVATE key —"
    echo    "  your SSH private key works; sops keys derive from it via ssh-to-age)."
    echo    "  Point at a file, e.g. /run/media/<usb>/id_ed25519"
    read -rp "→ Key file: " KEY_FILE
    if grep -q '^AGE-SECRET-KEY' "$KEY_FILE"; then
      cp "$KEY_FILE" /tmp/sops-age-keys.txt
    elif ! ssh-to-age -private-key -i "$KEY_FILE" -o /tmp/sops-age-keys.txt; then
      read -rsp "Encrypted SSH key, enter its passphrase: " KEY_PASS; echo
      SSH_TO_AGE_PASSPHRASE="$KEY_PASS" \
        ssh-to-age -private-key -stdinpass -i "$KEY_FILE" -o /tmp/sops-age-keys.txt
      unset KEY_PASS
    fi
    chmod 600 /tmp/sops-age-keys.txt
    export SOPS_AGE_KEY_FILE=/tmp/sops-age-keys.txt

    ENCRYPT=$(nix eval --json ".#nixosConfigurations.{{host}}.config.custom.disko.encrypt" 2>/dev/null || echo false)
    if [ "$ENCRYPT" = "true" ]; then
      while true; do
        read -rsp "→ LUKS passphrase (stored in /tmp/luks.key for disko): " LU && echo
        read -rsp "→ Confirm LUKS passphrase: " LU2 && echo
        if [ "$LU" != "$LU2" ]; then
          echo "✗ Passphrases don't match — retrying"
          unset LU LU2
          continue
        fi
        unset LU2
        printf '%s' "$LU" > /tmp/luks.key
        break
      done
      unset LU
      chmod 600 /tmp/luks.key
    # temporary, uncommitted ISO-only override so disko reads the keyfile
    # (idempotent: used only if the clone starts with passwordFile absent)
    grep -q 'passwordFile = "/tmp/luks.key"' "modules/hosts/{{host}}/default.nix" || \
      sed -i 's/encrypt = true;/encrypt = true;\n          passwordFile = "\/tmp\/luks.key";/' \
        "modules/hosts/{{host}}/default.nix"
    [ -z "{{device}}" ] || \
      sed -i 's|device = .*|device = "{{device}}";|' "modules/hosts/{{host}}/default.nix"
    fi

    # Smallest closure first: console fits an ISO's tmpfs RAM (its nix
    # store IS ram), minimal needs a beefier installer, full is post-switch.
    FLAKE_REF=""
    for v in console minimal; do
      if nix eval --raw ".#nixosConfigurations.{{host}}-$v.config.system.name" >/dev/null 2>&1; then
        FLAKE_REF=".#{{host}}-$v"
        break
      fi
    done
    if [ -z "$FLAKE_REF" ]; then
      echo "✗ No '-console' or '-minimal' variant for {{host}} — refusing a"
      echo "  full-desktop install from a raw installer. Deploy the full"
      echo "  profile post-install:"
      echo "    nix-shell -p just --run \"just --justfile justfile switch\""
      exit 1
    fi
    echo "→ Installing variant: $FLAKE_REF (full desktop comes with the post-install switch)"

    echo "→ Installing $FLAKE_REF on this machine (disko will wipe the disk!)"
    # Phase 1: partition + mount. Kept separate so we can seed a machine-id
    # before install — systemd-boot crashes on an empty one, and impermanence
    # means the target root has none yet (the ISO has a live one to copy).
    nix run github:nix-community/nixos-anywhere -- \
      --flake "$FLAKE_REF" \
      --generate-hardware-config nixos-generate-config \
        "./modules/hosts/{{host}}/_hardware.nix" \
      --phases kexec,disko \
      "root@localhost"
    # Seed the machine-id into the persisted locations — /etc/machine-id is
    # bind-mounted read-only from /persistent at boot, and systemd-boot
    # crashes on an empty id, so the ephemeral /mnt/etc copy alone won't do
    ssh root@localhost 'mkdir -p /mnt/persistent/etc /mnt/persistent/var/lib/nixos /mnt/etc /mnt/var/lib/nixos
      cp /etc/machine-id /mnt/persistent/etc/machine-id
      cp /etc/machine-id /mnt/persistent/var/lib/nixos/machine-id
      cp /etc/machine-id /mnt/etc/machine-id
      cp /etc/machine-id /mnt/var/lib/nixos/machine-id'

    # Phase 2: install closure + bootloader
    nix run github:nix-community/nixos-anywhere -- \
      --flake "$FLAKE_REF" \
      --phases install \
      "root@localhost"

    echo "→ Adding machine age key to .sops.yaml"
    # sshd hasn't run in the chroot yet, so host keys may not exist
    [ -f /mnt/etc/ssh/ssh_host_ed25519_key.pub ] || \
      ssh-keygen -q -t ed25519 -N "" -f /mnt/etc/ssh/ssh_host_ed25519_key
    AGE_KEY=$(ssh-to-age -i /mnt/etc/ssh/ssh_host_ed25519_key.pub)
    if grep -qF "$AGE_KEY" .sops.yaml 2>/dev/null; then
      echo "→ Key already present — nothing to do"
    else
      sed -i "1,/^  - age:/{/^  - age:/s/$/, $AGE_KEY/}" .sops.yaml
    fi

    for f in $(find . -name 'secrets.yaml' -type f); do
      if grep -q '^sops:' "$f" 2>/dev/null; then
        echo "→ Rekeying: $f"
        sops updatekeys "$f" --yes
      fi
    done

    git add .sops.yaml modules/hosts/{{host}}/_hardware.nix
    # ISO has no git identity; set one locally so the bootstrap commit works
    git config user.name "Marviel Billante"
    git config user.email "marvielb@gmail.com"
    git commit -m "bootstrap {{host}}: hardware config + machine sops key"

    # Copy the repo (with this session's changes: sops key, hardware config)
    # into the user's persisted home so the installed system needs no re-clone
    REPO_DIR="/mnt/persistent/home/{{host}}/src/nixos-config"
    echo "→ Copying repo into $REPO_DIR (survives reboot)"
    mkdir -p "$(dirname "$REPO_DIR")"
    rm -rf /mnt/persistent/home/{{host}}/src/nixos-config
    cp -a /tmp/repo/. /mnt/persistent/home/{{host}}/src/nixos-config/
    chown -R 1000:100 /mnt/persistent/home/{{host}}/src/nixos-config

    echo "→ Done. Now: 'git push' from here, remove USB/notes, reboot."
    rm -f /tmp/sops-age-keys.txt /tmp/luks.key
    read -rp "Push now? [y/N] " P
    [[ "$P" == "y" || "$P" == "Y" ]] && git push



# Evaluate the whole flake (also evaluates all hosts)
check:
    nix flake check

# Build and run flake checks (persist invariants etc.)
test:
    nix flake check --print-build-logs

# Boot a host in a QEMU VM for interactive smoke-testing
vm host=host:
    nixos-rebuild build-vm --flake .#{{host}}

# Run linters on all nix files
lint:
    nix run nixpkgs#statix -- check .
    nix run nixpkgs#deadnix -- --fail .
    nix run nixpkgs#nixfmt -- --check $(git ls-files '*.nix')

# Format all nix files
fmt:
    nix run nixpkgs#nixfmt -- $(git ls-files '*.nix')

# Update flake.lock
update:
    nix flake update
