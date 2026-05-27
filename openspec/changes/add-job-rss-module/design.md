## Context

The portfolio host uses impermanence (ZFS snapshots + tmpfs via preservation). Currently only `lazy-email` (static site) is set up as a project module. The job-rss app is a Laravel PHP project that needs nginx + PHP-FPM, with persistent state only for the SQLite database. The existing non-impermanence config used NixOS containers; this design goes host-native for simplicity.

## Goals / Non-Goals

**Goals:**
- Serve Job RSS at `jobs.marvielb.com` via nginx + PHP-FPM on the host (no container)
- Use the Nix-built package from the `job-rss` flake as the document root
- PHP-FPM pool `jobs` runs as dedicated `${app}-jobs` system user (member of the `nginx` group)
- Persist the SQLite database at `/var/lib/jobs/database/database.sqlite`
- Persist writable storage at `/var/lib/jobs/storage`
- Automate first-time deploy setup (migrations, passport keys, passport client) via activation scripts
- Follow the `lazy-email.nix` module pattern (`{ inputs, ... }: { flake.nixosModules.<name> = ...; }`)

**Non-Goals:**
- Managing `.env` or config files via Nix (the project handles its own overrides)
- Container or MicroVM setup
- Persisting `vendor/` or other non-runtime Laravel directories

## Decisions

1. **Host-native PHP-FPM over container** — Simpler, fewer moving parts, matches the lazy-email pattern. The non-impermanence config used containers for isolation, but impermanence already provides filesystem isolation and ZFS rollbacks.

2. **`php83` explicitly** — Matches the flake's build-time PHP version, avoiding runtime mismatches.

3. **PHP-FPM socket ownership** — `listen.owner` set to nginx user so the socket is readable by nginx without running PHP-FPM as root.

4. **Database at `/var/lib/jobs/database/` (explicitly preserved)** — Under `/var/lib/` for system-managed app state, avoiding home directory persistence issues. The flake-built package is read-only in the Nix store; only the mutable database lives on the filesystem. The database file is explicitly listed in `preservation.nix` under `files` (alongside `/var/lib/jobs/` which already covers it as a directory) for clarity that it's intended to persist.

5. **`APP_KEY` via pool `settings."env[APP_KEY]"`** — PHP-FPM pool `settings."env[KEY]"` provides proper quoting for base64 values (unlike `phpEnv` which can mangle `=` signs). Laravel reads `$_ENV` before `.env`, so setting it in the module overrides the placeholder from the package build.

6. **All env vars via pool `settings."env[KEY]"`** — `APP_KEY`, `DB_CONNECTION`, `DB_DATABASE`, and `LARAVEL_STORAGE_PATH` are all set as `env[KEY]` entries in the PHP-FPM pool settings, providing proper quoting and landing in `$_ENV` where Laravel's `env()` helper checks first. This is more consistent than mixing `fastcgi_param` (nginx), `phpEnv` (NixOS option), and `env[]` (pool setting). `LARAVEL_STORAGE_PATH` was previously sent via `fastcgi_param` but moved to `env[]` for consistency — now functional with `variables_order = "EGPCS"`.

7. **Activation script for directory creation** — `system.activationScripts.jobRssStorage` creates the storage tree and sets ownership on every `nixos-rebuild switch` (depends on `users` so the system user exists before chown). With preservation persisting `/var/lib/jobs` across reboots, this only needs to run once — subsequent boots restore the directories automatically. Simpler than a `preStart` hook on the PHP-FPM service, and avoids the risk of a failed mkdir blocking service startup.

8. **Dedicated `${app}-jobs` system user** — Created via `projectUser` variable (`users.users."${projectUser}"`) as a system user (`isSystemUser = true`) in the `nginx` group. The PHP-FPM pool runs as `projectUser:nginx`, limiting blast radius — `${app}-jobs` has no shell, no sudo, no SSH keys, unlike `portfolio` which has passwordless sudo access. Named with the app prefix to namespace users per project.

9. **`variables_order = "EGPCS"`** — NixOS's PHP package defaults to `"GPCS"` (no 'E'), so `$_ENV` is never populated from the process environment. Pool `env[]` settings (like `APP_KEY`) need 'E' in `variables_order` to appear in `$_ENV`, which is where Laravel's `env()` helper checks first.

10. **Deploy setup via activation script** — `system.activationScripts.jobRssDeploy` runs Laravel's `migrate --force` (idempotent), `passport:keys` (no-op if keys exist), and `passport:client --client` (guarded by a sqlite3 check for duplicate clients) on every `nixos-rebuild switch`. After passport setup, it checks if `onlinejobsph_job_listings` and `indeed_job_listings` tables are both empty — if so, runs `app:scrape` to populate initial data. Depends on `users` and `jobRssStorage` so the user and storage directories exist first. A final `chown` fixes ownership of any files created as root (e.g., passport key files). This automates the manual setup steps from the project's README without requiring interactive shell access.

## Risks / Trade-offs

- **No separation between app updates and DB schema** — When the flake input updates (new package build), migrations run automatically on the next `nixos-rebuild switch`. This is safe (migrations are idempotent) but means schema changes are coupled to system updates. Rebuild locally first if you need to review migrations before deploying.
- **SQLite performance at scale** — SQLite is fine for single-user RSS aggregation but won't handle concurrent writes. Acceptable for this use case.
- **No `.env` management** — App config overrides are manual or done elsewhere. The module provides enough env vars to connect the DB and set the app key.
- **Activation script doesn't run at boot** — Only runs on `nixos-rebuild switch`. If restoration from preservation is incomplete, directories won't be recreated until next rebuild. Deploy commands (migrations, passport) also only run on rebuild, which is acceptable since they mutate persistent state.
