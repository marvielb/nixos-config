{ ... }: {
  flake.modules.nixos.shell_pi =
    let
      # Provider credentials: secret name in secrets.yaml ↔ env var pi's
      # provider adapters read (pi docs → providers.md). Add a pair here
      # to wire another provider.
      apiSecrets = [
        {
          key = "pi_opencode_go_api_key";
          env = "OPENCODE_API_KEY";
        }
        {
          # OpenRouter — cheap/free worker models for pi-blackhole.
          key = "openrouter_api_key";
          env = "OPENROUTER_API_KEY";
        }
      ];
    in
    { lib, config, ... }: {
      # Decrypt at activation using the host SSH key; readable by normal
      # users so interactive shells can export them to pi.
      sops.secrets = lib.listToAttrs (
        lib.map (s: lib.nameValuePair s.key {
          sopsFile = ./secrets.yaml;
          mode = "0440";
          group = "users";
        }) apiSecrets
      );

      # Export the keys to every interactive bash shell; pi reads them
      # from the process environment at launch.
      programs.bash.interactiveShellInit = lib.concatStringsSep "\n" (
        lib.map (s: ''
          [ -f /run/secrets/${s.key} ] && \
            export ${s.env}="$(cat /run/secrets/${s.key})"
        '') apiSecrets
      );

      home-manager.sharedModules = [
        ({ pkgs, ... }: {
          programs.pi-coding-agent = {
            enable = true;
            settings.defaultProvider = "opencode-go";

            # pi packages (extensions, skills, prompts, themes) are picked up
            # from this declarations list at startup. Unversioned npm sources
            # float to latest: pi checks the registry at launch (notification
            # only) and applies on `pi update --extensions`.
            settings.packages = [ "npm:pi-blackhole" ];

            # pi reconciles npm-source package installs itself — give it
            # npm/node on the wrapped binary's PATH.
            extraPackages = [ pkgs.nodejs ];
          };
        })
      ];

      # Runtime state only: sessions + model catalog cache live in ~/.pi.
      custom.persist.home.directories = [ ".pi" ];
    };
}
