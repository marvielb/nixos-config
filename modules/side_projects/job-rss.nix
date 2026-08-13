{ inputs, ... }: {
  flake.modules.nixos.side_projects_job-rss =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      domain = "jobs.marvielb.com";
      appPkg = inputs.job-rss.outputs.packages.${pkgs.system}.job-rss;
      appDir = "/var/lib/jobs";
      databaseFile = "${appDir}/database/database.sqlite";
      app = "jobs";
      projectUser = "${app}-jobs";
    in
    {
      sops.secrets.job_rss_app_key = {
        sopsFile = ./secrets.yaml;
      };

      sops.templates."job-rss.env" = {
        content = "APP_KEY=${config.sops.placeholder.job_rss_app_key}";
        mode = "0440";
      };

      custom.persist.root = {
        directories = [ appDir ];
        files = [ databaseFile ];
      };

      services = {
        nginx = {
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
            locations = {
              "/".tryFiles = "$uri $uri/ /index.php$is_args$args";
              "/favicon.ico".extraConfig = ''
                access_log off; log_not_found off;
              '';
              "/robots.txt".extraConfig = ''
                access_log off; log_not_found off;
              '';
              "~ \\.php$".extraConfig = ''
                fastcgi_split_path_info ^(.+\.php)(/.+)$;
                fastcgi_pass unix:${config.services.phpfpm.pools.${app}.socket};
                fastcgi_index index.php;
                include ${pkgs.nginx}/conf/fastcgi.conf;
              '';
              "~ /\\.(?!well-known).*".extraConfig = ''
                deny all;
              '';
            };
          };
        };

        phpfpm = {
          phpOptions = ''
            opcache.enable=0
            variables_order = "EGPCS"
          '';

          pools.${app} = {
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
              "clear_env" = "no";
              "php_admin_value[error_log]" = "stderr";
              "php_admin_flag[log_errors]" = true;
              "catch_workers_output" = true;
              "env[DB_CONNECTION]" = ''"sqlite"'';
              "env[DB_DATABASE]" = ''"${databaseFile}"'';
              "env[LARAVEL_STORAGE_PATH]" = ''"${appDir}/storage"'';
            };
            phpEnv."PATH" = lib.makeBinPath [ pkgs.php83 ];
          };
        };
      };

      users.users."${projectUser}" = {
        isSystemUser = true;
        group = config.services.nginx.group;
      };

      systemd.services."phpfpm-${app}".serviceConfig.EnvironmentFile = [
        config.sops.templates."job-rss.env".path
      ];

      system.activationScripts.jobRssStorage = {
        text = ''
          mkdir -p ${appDir}/{database,storage/{logs,framework/{views,cache,sessions},app}}
          chmod -R 755 ${appDir}
          chown -R ${projectUser}:nginx ${appDir}
        '';
        deps = [ "users" ];
      };

      system.activationScripts.jobRssDeploy = {
        text = ''
          echo "job-rss: running deploy setup..."

          set -a
          . ${config.sops.templates."job-rss.env".path}
          set +a

          cd ${appPkg}/share/php/job-rss
          export LARAVEL_STORAGE_PATH="${appDir}/storage"
          export DB_CONNECTION=sqlite
          export DB_DATABASE="${databaseFile}"

          PHP="${pkgs.php83}/bin/php -d variables_order=EGPCS"

          echo "job-rss: running migrations..."
          $PHP artisan migrate --force

          echo "job-rss: generating passport keys..."
          $PHP artisan passport:keys || true

          echo "job-rss: checking for passport client..."
          if ! ${pkgs.sqlite}/bin/sqlite3 "${databaseFile}" \
            "SELECT COUNT(*) FROM oauth_clients WHERE name = 'Job RSS Client';" \
            2>/dev/null | grep -q '[1-9]'; then
            echo "job-rss: creating passport client..."
            $PHP artisan passport:client --client --name="Job RSS Client" --no-interaction
          fi

          echo "job-rss: checking for existing job listings..."
          JOB_COUNT=$(${pkgs.sqlite}/bin/sqlite3 "${databaseFile}" \
            "SELECT (SELECT COUNT(*) FROM onlinejobsph_job_listings) + (SELECT COUNT(*) FROM indeed_job_listings);" \
            2>/dev/null || echo "0")
          echo "job-rss: found $JOB_COUNT existing listings"
          if [ "$JOB_COUNT" = "0" ]; then
            echo "job-rss: no listings found, dispatching initial scrape..."
            $PHP artisan app:scrape
            echo "job-rss: scrape dispatched, queue worker will process it"
          fi

          echo "job-rss: fixing storage ownership..."
          chown -R ${projectUser}:nginx ${appDir}/storage
          echo "job-rss: deploy setup done"
        '';
        deps = [
          "users"
          "jobRssStorage"
          "setupSecrets"
        ];
      };

      systemd.services."${app}-queue-worker" = {
        description = "Job RSS queue worker";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          User = projectUser;
          WorkingDirectory = "${appPkg}/share/php/job-rss";
          EnvironmentFile = [ config.sops.templates."job-rss.env".path ];
          Environment = [
            "LARAVEL_STORAGE_PATH=${appDir}/storage"
            "DB_CONNECTION=sqlite"
            "DB_DATABASE=${databaseFile}"
            "QUEUE_CONNECTION=database"
            "PATH=${lib.makeBinPath [ pkgs.php83 ]}"
          ];
          ExecStart = "${pkgs.php83}/bin/php -d variables_order=EGPCS artisan queue:work --sleep=3 --tries=3";
          Restart = "always";
          RestartSec = 5;
        };
      };
    };
}
