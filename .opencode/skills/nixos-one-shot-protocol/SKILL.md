---
name: nixos-one-shot-protocol
description: Follow the one-shot protocol before creating any new module in this repo — research, plan all files, present in one response
license: MIT
compatibility: opencode
metadata:
  scope: nixos-config
---

# One-Shot Protocol

**Run this before creating any new module.** It ensures the full file plan is determined up
front and presented in a single response, avoiding half-baked iterative edits.

1. Check `RESEARCH.md` for cached findings on the relevant pattern/feature
2. If not found, check the reference repo (https://github.com/k1ng440/dotfiles.nix) for inspiration on structure, conventions, and persistence
3. **Determine the complete set of files needed** — every file to create and every file to modify — by examining all relevant existing patterns in the repo first
4. Present the full plan (create + modify files with contents) in a single response
5. Append new general findings to `RESEARCH.md` so they're cached for future sessions

## Parallel Execution

Steps 1-3 are independent. Dispatch them in **parallel** with the `task` tool
to the `nixos-research` subagent (its three research tracks map 1:1 to the
steps below):

- Step 1 → `explore` / `general`: grep RESEARCH.md for relevant cached findings (track 1)
- Step 2 → `scout`: fetch/analyze the reference repo for the pattern (track 2)
- Step 3 → `explore`: find all similar existing modules and their conventions (track 3)

You may also dispatch `explore` for broader codebase search, but `nixos-research`
is preferred — it returns repo-specific findings and a reusable-pattern summary.

Synthesize the results into the complete file plan before writing anything.
