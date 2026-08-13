_: {
  flake.modules.nixos.gui_zathura = _: {
    home-manager.sharedModules = [
      ({ pkgs, ... }: {
        programs.zathura.enable = true;
        home.packages = [ pkgs.zathuraPkgs.zathura_pdf_mupdf ];
      })
    ];
  };
}
