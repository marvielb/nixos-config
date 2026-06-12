# NixOS Config — Build helpers

host := "practice"

# Build the system (dry run, doesn't switch)
build:
    sudo nixos-rebuild dry-build --flake .#{{host}}

# Build and activate
switch:
    sudo nixos-rebuild switch --flake .#{{host}}

# Build a VM for testing
vm host=host:
    nixos-rebuild build-vm --flake .#{{host}}

# Deploy to a remote host
deploy host=host:
    nixos-rebuild --target-host {{host}}@{{host}}.box --sudo switch --flake .#{{host}} --ask-sudo-password

# Evaluate the whole flake
check:
    nix flake check

# Format all nix files
fmt:
    nix fmt

# Update flake.lock
update:
    nix flake update
