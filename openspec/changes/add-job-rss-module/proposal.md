## Why

The portfolio host at `jobs.marvielb.com` currently runs a Laravel job RSS aggregator via a non-impermanence config using NixOS containers. Now that the portfolio host uses impermanence (ZFS snapshots + tmpfs), we need a declarative module that sets up the app natively (no container) while persisting only the SQLite database. This mirrors the pattern used by `lazy-email.nix` for the email app.

## What Changes

- Add `job-rss` flake input (github:marvielb/job-rss) to `flake.nix`
- Create `modules/hosts/portfolio/projects/job-rss.nix` — a new NixOS module providing:
  - Nginx virtual host for `jobs.marvielb.com` with PHP-FPM
  - PHP-FPM pool `jobs` running as the `portfolio` user
  - Environment variables: `DB_CONNECTION=sqlite`, `DB_DATABASE=/home/portfolio/jobs/database/database.sqlite`, and `APP_KEY`
- Register `self.nixosModules.jobRss` in `modules/hosts/portfolio/default.nix`
- Add `/home/portfolio/jobs/database` to preservation rules in `modules/hosts/portfolio/preservation.nix` so the SQLite DB survives reboots

## Capabilities

### New Capabilities
- `job-rss-hosting`: Serve the Job RSS Laravel app at jobs.marvielb.com with nginx + PHP-FPM, persistent database under the portfolio user's home directory.

### Modified Capabilities
- `portfolio-preservation`: Add job-rss database directory to preservation rules for the portfolio user.

## Impact

- `flake.nix`: New `job-rss` input pinned to GitHub
- `modules/hosts/portfolio/projects/`: New `job-rss.nix` module
- `modules/hosts/portfolio/default.nix`: Import the new module
- `modules/hosts/portfolio/preservation.nix`: Add database directory to user directories
- Requires `php83` and composer from nixpkgs at runtime (already available)
