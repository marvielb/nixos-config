## 1. Flake Setup

- [x] 1.1 Add `job-rss` input to `flake.nix` — `job-rss.url = "github:marvielb/job-rss";`

## 2. Project Module

- [x] 2.1 Create `modules/hosts/portfolio/projects/job-rss.nix` with nginx virtual host for `jobs.marvielb.com`
- [x] 2.2 Add PHP-FPM pool `jobs` with `php83`, running as `portfolio` user
- [x] 2.3 Set environment variables: `DB_CONNECTION`, `DB_DATABASE`, `APP_KEY`
- [x] 2.4 Add standard PHP nginx locations (try_files, fastcgi pass, static files, deny hidden files)
- [x] 2.5 Add firewall rule for SSH port if needed (verify existing portfolio user access) — **N/A**: `networking.firewall.enable = false` already set in `configuration.nix`, SSH already enabled

## 3. Module Registration

- [x] 3.1 Register `self.nixosModules.jobRss` in `modules/hosts/portfolio/default.nix`

## 4. Impermanence

- [x] 4.1 Move app state from `/home/portfolio/jobs/` to `/var/lib/jobs/`
- [x] 4.2 Add `"/var/lib/jobs"` to preservation directories and remove user-specific entries
