{
  nixConfig = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [ "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=" ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    wrappers = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    preservation.url = "github:nix-community/preservation";

    lazy-email.url = "github:marvielb/lazy-email";

    job-rss.url = "github:marvielb/job-rss";

    noctalia = {
      url = "github:noctalia-dev/noctalia/legacy-v4";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, nixpkgs, ... }:
    let
      inherit (nixpkgs.lib.fileset) toList fileFilter;
      import-tree = path:
        toList (fileFilter
          (file: file.hasExt "nix" && !(nixpkgs.lib.hasPrefix "_" file.name))
          path);
    in
    flake-parts.lib.mkFlake { inherit inputs; }     {
      imports = import-tree ./modules;
    };
}
