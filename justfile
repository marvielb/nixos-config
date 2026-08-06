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
