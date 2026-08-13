_: {
  flake.modules.nixos.gui_logseq =
    { pkgs, ... }:
    let
      logseq-wrapped = pkgs.symlinkJoin {
        name = "logseq-wrapped";
        paths = [ pkgs.logseq ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          rm $out/bin/logseq
          makeWrapper ${pkgs.logseq}/bin/logseq $out/bin/logseq \
            --add-flags "--enable-features=UseOzonePlatform --ozone-platform=wayland"
        '';
      };
    in
    {
      nixpkgs.config.permittedInsecurePackages = [ "electron-39.8.10" ];

      environment.systemPackages = [ logseq-wrapped ];
      custom.persist.home.directories = [ ".logseq" ];
    };
}
