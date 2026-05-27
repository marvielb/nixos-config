{ inputs, ... }: {
  flake.nixosModules.jobRss = { pkgs, config, lib, ... }:
    let
      domain = "jobs.marvielb.com";
      appPkg = inputs.job-rss.outputs.packages.${pkgs.system}.job-rss;
      appDir = "/var/lib/jobs";
      databaseFile = "${appDir}/database/database.sqlite";
      app = "jobs";
      projectUser = "${app}-jobs";
    in
    {
      services.nginx = {
        enable = true;
        virtualHosts.${domain} = {
          root = "${appPkg}/share/php/job-rss/public";
          extraConfig = ''
            add_header X-Frame-Options "SAMEORIGIN";
            add_header X-XSS-Protection "1; mode=block";
            add_header X-Content-Type-Options "nosniff";
            index index.html index.htm index.php;
            error_page 404 /index.php;
          '';
          locations."/".tryFiles = "$uri $uri/ /index.php$is_args$args";
          locations."/favicon.ico".extraConfig = ''
            access_log off; log_not_found off;
          '';
          locations."/robots.txt".extraConfig = ''
            access_log off; log_not_found off;
          '';
          locations."~ \\.php$".extraConfig = ''
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass unix:${config.services.phpfpm.pools.${app}.socket};
            fastcgi_index index.php;
            include ${pkgs.nginx}/conf/fastcgi.conf;
          '';
          locations."~ /\\.(?!well-known).*".extraConfig = ''
            deny all;
          '';
        };
      };

      users.users."${projectUser}" = {
        isSystemUser = true;
        group = config.services.nginx.group;
      };

      services.phpfpm.phpOptions = ''
        opcache.enable=0
        variables_order = "EGPCS"
      '';

      services.phpfpm.pools.${app} = {
        user = projectUser;
        group = config.services.nginx.group;
        phpPackage = pkgs.php83;
        settings = {
          "listen.owner" = config.services.nginx.user;
          "pm" = "dynamic";
          "pm.max_children" = 32;
          "pm.max_requests" = 500;
          "pm.start_servers" = 1;
          "pm.min_spare_servers" = 1;
          "pm.max_spare_servers" = 1;
          "php_admin_value[error_log]" = "stderr";
          "php_admin_flag[log_errors]" = true;
          "catch_workers_output" = true;
          "env[APP_KEY]" = ''"base64:HzERkk6bmC2n4vOUz+ANQis0qlqia5ouP3rwq/U8mBA="'';
          "env[DB_CONNECTION]" = ''"sqlite"'';
          "env[DB_DATABASE]" = ''"${databaseFile}"'';
          "env[LARAVEL_STORAGE_PATH]" = ''"${appDir}/storage"'';
        };
        phpEnv."PATH" = lib.makeBinPath [ pkgs.php83 ];
      };

      systemd.services."phpfpm-${app}" = {
        preStart = ''
          mkdir -p ${appDir}/storage/{logs,framework/{views,cache,sessions},app}
          chmod -R 755 ${appDir}
          chown -R ${projectUser}:nginx ${appDir}
        '';
      };
    };
}
