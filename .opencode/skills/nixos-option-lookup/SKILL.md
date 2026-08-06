---
name: nixos-option-lookup
description: Look up the correct NixOS / Home Manager / Stylix option or package source when searching this repo's options
license: MIT
compatibility: opencode
metadata:
  scope: nixos-config
---

# NixOS Option Lookup — Choose the Right Source

The MCP search tool queries different sources depending on what you pass:

| What you're looking for | `action` | `type` / `source` |
|---|---|---|
| NixOS option (e.g. `services.nginx.enable`) | search | `type: options` |
| Home Manager option (e.g. `programs.bash.*`) | search | `source: home-manager` |
| Stylix target options (`stylix.targets.<name>.*`) | search | `source: home-manager` |
| Nix packages | search/info | `type: packages` (default) |
| Option details / exact declaration | info | `type: option` (NixOS) |

## Stylix Gotchas

**Stylix targets** (`stylix.targets.<name>.*`) are **Home Manager options** — search with
`source: home-manager`, not `type: options`. The stylix docs at
https://nix-community.github.io/stylix/ are the authoritative reference.

**`stylix.autoEnable = true`** (set in `modules/stylix.nix`) enables theming for all
supported targets automatically. Before manually adding `stylix.targets.<name>.enable`,
check whether the target is already covered by `autoEnable`.
