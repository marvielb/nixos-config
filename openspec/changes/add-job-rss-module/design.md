## Context

The portfolio host uses impermanence (ZFS snapshots + tmpfs via preservation). Currently only `lazy-email` (static site) is set up as a project module. The job-rss app is a Laravel PHP project that needs nginx + PHP-FPM, with persistent state only for the SQLite database. The existing non-impermanence config used NixOS containers; this design goes host-native for simplicity.

## Goals / Non-Goals

**Goals:**
- Serve Job RSS at `jobs.marvielb.com` via nginx + PHP-FPM on the host (no container)
- Use the Nix-built package from the `job-rss` flake as the document root
- PHP-FPM pool `jobs` runs as `portfolio` (the host's main user, a member of the `nginx` group)
- Persist the SQLite database at `/var/lib/jobs/database/database.sqlite`
- Persist writable storage at `/var/lib/jobs/storage`
- Follow the `lazy-email.nix` module pattern (`{ inputs, ... }: { flake.nixosModules.<name> = ...; }`)

**Non-Goals:**
- Managing `.env` or config files via Nix (the project handles its own overrides)
- Container or MicroVM setup
- Persisting `vendor/` or other non-runtime Laravel directories

## Decisions

1. **Host-native PHP-FPM over container** — Simpler, fewer moving parts, matches the lazy-email pattern. The non-impermanence config used containers for isolation, but impermanence already provides filesystem isolation and ZFS rollbacks.

2. **`php83` explicitly** — Matches the flake's build-time PHP version, avoiding runtime mismatches.

3. **PHP-FPM socket ownership** — `listen.owner` set to nginx user so the socket is readable by nginx without running PHP-FPM as root.

4. **Database at `/var/lib/jobs/database/`** — Under `/var/lib/` for system-managed app state, avoiding home directory persistence issues. The flake-built package is read-only in the Nix store; only the mutable database lives on the filesystem.

5. **`APP_KEY` via pool `settings."env[APP_KEY]"`** — PHP-FPM pool `settings."env[KEY]"` provides proper quoting for base64 values (unlike `phpEnv` which can mangle `=` signs). Laravel reads `$_ENV` before `.env`, so setting it in the module overrides the placeholder from the package build.

6. **Storage at `/var/lib/jobs/storage/` via `fastcgi_param`** — The Nix store is read-only, so Laravel's runtime storage (logs, compiled views, cache) must live on a writable filesystem. `LARAVEL_STORAGE_PATH` is sent via nginx `fastcgi_param` (landing in `$_SERVER`) to avoid PHP-FPM env propagation issues. `/var/lib/` already lives under preservation, avoiding the bind-mount-overwrite problem with home directories.

7. **`preStart` on PHP-FPM service for directory creation** — `systemd.services.phpfpm-${app}.preStart` creates the storage tree and sets ownership on boot (after all mounts). This is more reliable than activation scripts (unpredictable ordering with impermanence mounts) and runs on every boot, not just `nixos-rebuild switch`.

8. **PHP-FPM pool runs as `portfolio` (not a dedicated user)** — The pool runs as the host's main user for simplicity. This trades isolation for convenience — `portfolio` has passwordless sudo, so a compromised app has full access. Acceptable for this single-user deployment.

9. **`variables_order = "EGPCS"`** — Ensures `$_ENV` and `$_SERVER` are populated correctly for both `env[]`-based and `fastcgi_param`-based env vars.

## Risks / Trade-offs

- **No separation between app updates and DB schema** — When the flake input updates (new package build), the DB might need migrations. Mitigation: deploy manually via `nixos-rebuild switch` after verifying migrations locally.
- **SQLite performance at scale** — SQLite is fine for single-user RSS aggregation but won't handle concurrent writes. Acceptable for this use case.
- **No `.env` management** — App config overrides are manual or done elsewhere. The module provides enough env vars to connect the DB and set the app key.
- **`preStart` failure blocks PHP-FPM** — If the storage directory setup fails (mkdir/chown), the PHP-FPM service stays in a failed state. Acceptable — indicates a systemic issue that should block startup.
