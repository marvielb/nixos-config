{ inputs, ... }: {
  flake.modules.nixos.side_projects_lazy-email =
    { pkgs, ... }:
    let
      domain = "email.marvielb.com";
      dataDir = inputs.lazy-email.outputs.packages.${pkgs.system}.lazy-email.override {
        secrets = {
          googleClientId = "688197537261-an2eq5to4qkj407vik4qa6vo4ukj6r8n.apps.googleusercontent.com";
          googleApiKey = "AIzaSyCJXh3TaLKiLpAh8YeDoJzK-yRe5neZH3Q";
          gmailDiscoveryDoc = "https://www.googleapis.com/discovery/v1/apis/gmail/v1/rest";
        };
      };
    in
    {
      services.nginx = {
        enable = true;
        virtualHosts.${domain} = {
          root = dataDir;
          locations."/".tryFiles = "$uri $uri/ /index.html";
        };
      };
    };
}
