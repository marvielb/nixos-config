{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    preservation.url = "github:nix-community/preservation";

    lazy-email.url = "github:marvielb/lazy-email";

    job-rss.url = "github:marvielb/job-rss";
  };

  outputs = inputs@{ flake-parts, nixpkgs, ... }:
    let
      inherit (nixpkgs.lib.fileset) toList fileFilter;
      import-tree = path:
        toList (fileFilter
          (file: file.hasExt "nix" && !(nixpkgs.lib.hasPrefix "_" file.name))
          path);
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = import-tree ./modules;
    };
}
