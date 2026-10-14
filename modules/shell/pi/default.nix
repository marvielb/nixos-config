{ ... }: {
  flake.modules.nixos.shell_pi =
    let
      # OpenCode Go (provider id: opencode-go). Both OpenCode Zen and Go
      # authenticate via OPENCODE_API_KEY (pi docs → providers.md).
      # To use another provider, swap this and the sops secret key name.
      apiKeyVar = "OPENCODE_API_KEY";
      apiKeySecret = "pi_opencode_go_api_key";
    in
    { config, ... }: {
      # Decrypt at activation using the host SSH key; readable by normal
      # users so interactive shells can export it to pi.
      sops.secrets.${apiKeySecret} = {
        sopsFile = ./secrets.yaml;
        mode = "0440";
        group = "users";
      };

      # Export the key to every interactive bash shell. pi reads
      # ${apiKeyVar} from the process environment at launch.
      programs.bash.interactiveShellInit = ''
        [ -f /run/secrets/${apiKeySecret} ] && \
          export ${apiKeyVar}="$(cat /run/secrets/${apiKeySecret})"
      '';

      home-manager.sharedModules = [
        ({ ... }: {
          programs.pi-coding-agent = {
            enable = true;
            settings.defaultProvider = "opencode-go";
          };
        })
      ];

      # Runtime state only: sessions + model catalog cache live in ~/.pi.
      custom.persist.home.directories = [ ".pi" ];
    };
}
