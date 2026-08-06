{ inputs, ... }: {
  flake.modules.nixos.security_sops-nix = { pkgs, ... }: {
    imports = [ inputs.sops-nix.nixosModules.sops ];

    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    sops.age.keyFile = null;

    sops.secrets.sample_secret = {
      sopsFile = ./test/secrets.yaml;
    };

    environment.systemPackages = with pkgs; [
      sops
      ssh-to-age
    ];
  };
}
