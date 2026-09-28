{ inputs, ... }: {
  flake.modules.nixos.gui_logseq =
    { pkgs, ... }:
    let
      stable = import inputs.nixpkgs-stable {
        localSystem = pkgs.system;
        config = {
          permittedInsecurePackages = [ "electron-37.10.2" ];
        };
      };

      logseq-wrapped = stable.symlinkJoin {
        name = "logseq-wrapped";
        paths = [ stable.logseq ];
        nativeBuildInputs = [ stable.makeWrapper ];
        postBuild = ''
          rm $out/bin/logseq
          makeWrapper ${stable.logseq}/bin/logseq $out/bin/logseq \
            --add-flags "--enable-features=UseOzonePlatform --ozone-platform=wayland"
        '';
      };
    in
    {
      environment.systemPackages = [ logseq-wrapped ];
      custom.persist.home.directories = [ ".logseq" ];
    };
}
