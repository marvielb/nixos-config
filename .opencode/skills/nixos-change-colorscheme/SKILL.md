---
name: nixos-change-colorscheme
description: Switch the global colorscheme for this repo (stylix + neovim) via the custom.colorscheme option
license: MIT
compatibility: opencode
metadata:
  scope: nixos-config
---

# Changing the Colorscheme

The canonical colorscheme name lives in `modules/configuration.nix` under
`custom.colorscheme`. To switch themes globally (stylix + neovim + anything else
that reads the option):

1. Set `custom.colorscheme` in `configuration.nix` to the lazyvim-style name
   (e.g. `"tokyonight-night"`)
2. If stylix needs a different filename, add the mapping in `modules/stylix.nix`
3. Rebuild: `just switch`

## Canonical name → base16 mapping

| `custom.colorscheme`   | base16 filename          | Both? |
|------------------------|--------------------------|-------|
| `catppuccin-mocha`     | catppuccin-mocha.yaml    | Yes   |
| `kanagawa`             | kanagawa.yaml            | Yes   |
| `tokyonight-day`       | tokyo-night-day.yaml     | No    |
| `tokyonight-moon`      | tokyo-night-moon.yaml    | No    |
| `tokyonight-night`     | tokyo-night-night.yaml   | No    |
| `tokyonight-storm`     | tokyo-night-storm.yaml   | No    |

If you add a theme that isn't in the mapping, the build will fail with a clear
`throw` error telling you to update `modules/stylix.nix`.
