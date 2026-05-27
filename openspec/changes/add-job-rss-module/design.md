## Context

The portfolio host uses impermanence (ZFS snapshots + tmpfs via preservation). Currently only `lazy-email` (static site) is set up as a project module. The job-rss app is a Laravel PHP project that needs nginx + PHP-FPM, with persistent state only for the SQLite database. The existing non-impermanence config used NixOS containers; this design goes host-native for simplicity.

## Goals / Non-Goals

**Goals:**
- Serve Job RSS at `jobs.marvielb.com` via nginx + PHP-FPM on the host (no container)
- Use the Nix-built package from the `job-rss` flake as the document root
- PHP-FPM pool `jobs` runs as user `portfolio` (no new user)
- Persist only the SQLite database at `/home/portfolio/jobs/database/database.sqlite`
- Follow the `lazy-email.nix` module pattern (`{ inputs, ... }: { flake.nixosModules.<name> = ...; }`)

**Non-Goals:**
- Managing `.env` or config files via Nix (the project handles its own overrides)
- Container or MicroVM setup
- Persisting `storage/`, `vendor/`, or other Laravel directories
- SSH user management (uses existing `portfolio` user)

## Decisions

1. **Host-native PHP-FPM over container** — Simpler, fewer moving parts, matches the lazy-email pattern. The non-impermanence config used containers for isolation, but impermanence already provides filesystem isolation and ZFS rollbacks.

2. **`php83` explicitly** — Matches the flake's build-time PHP version, avoiding runtime mismatches.

3. **PHP-FPM socket ownership** — `listen.owner` set to nginx user so the socket is readable by nginx without running PHP-FPM as root.

4. **Database at `/home/portfolio/jobs/database/`** — Flat under home, no `current/` subdir. Persistent via preservation. The flake-built package is read-only in the Nix store; only the mutable database lives on the filesystem.

5. **`APP_KEY` in phpEnv** — Laravel reads `$_ENV` before `.env`, so setting it in the module overrides the placeholder from the package build.

## Risks / Trade-offs

- **No separation between app updates and DB schema** — When the flake input updates (new package build), the DB might need migrations. Mitigation: deploy manually via `nixos-rebuild switch` after verifying migrations locally.
- **SQLite performance at scale** — SQLite is fine for single-user RSS aggregation but won't handle concurrent writes. Acceptable for this use case.
- **No `.env` management** — App config overrides are manual or done elsewhere. The module provides enough env vars to connect the DB and set the app key.
