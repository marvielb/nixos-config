{ ... }: throw ''
  _hardware.nix has not been generated for host 'marvielb'.

  Run nixos-anywhere with --generate-hardware-config to generate it:

    nix run github:nix-community/nixos-anywhere -- --flake .#marvielb --generate-hardware-config nixos-generate-config ./modules/hosts/marvielb/_hardware.nix root@<target-ip>

  After install, commit the generated file from the target machine.
''
