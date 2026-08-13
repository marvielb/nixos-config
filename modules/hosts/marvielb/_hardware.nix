# Stub — nixos-anywhere overwrites this on first deploy.
# Do not commit real hardware config here.
#
# Generate with:
#   nix run github:nix-community/nixos-anywhere -- --flake .#marvielb \
#     --generate-hardware-config nixos-generate-config \
#     ./modules/hosts/marvielb/_hardware.nix root@<target-ip>
#
# Keeping this a no-op (instead of a `throw`) lets `nix flake check`
# evaluate the host without a real machine; the generated config's
# fileSystems block is safely overridden by _disko.nix.
_: { }
