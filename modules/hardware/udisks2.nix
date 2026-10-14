{ ... }: {
  flake.modules.nixos.hardware_udisks2 = { ... }: {
    # Manage + mount removable/internal media via udisks2 (explicit; gvfs
    # pulls this in but it should not depend on being implicit).
    services.udisks2.enable = true;

    # udisks' default policy grants mounting only to sessions polkit deems
    # "active"; depending on the login path those sessions may not be
    # marked active, which turns mounting into an auth_admin roadblock.
    # Explicitly allow wheel members instead.
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (subject.isInGroup("wheel") && action.id.startsWith("org.freedesktop.udisks2.")) {
          return polkit.Result.YES;
        }
      });
    '';
  };
}
