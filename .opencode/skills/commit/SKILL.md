---
name: commit
description: Write Conventional Commits following industry best practices for clear, parseable commit messages
license: MIT
compatibility: opencode
metadata:
  audience: developers
  standard: conventional-commits-1.0.0
---

# Commit Skill — Conventional Commits

Teach the agent to write structured, meaningful Git commit messages following the [Conventional Commits v1.0.0](https://www.conventionalcommits.org/) specification.

## Structure

```
<type>(<scope>): <subject>

<body>

<footer(s)>
```

Each part is explained below.

## Types

Always lowercase. Pick the type that best describes the change:

| Type       | When to use                                         |
|------------|-----------------------------------------------------|
| `feat`     | A new feature or capability                         |
| `fix`      | A bug fix                                           |
| `docs`     | Documentation-only changes (README, comments, etc.) |
| `style`    | Formatting, whitespace, linting — no logic change   |
| `refactor` | Code restructuring — neither fix nor feature        |
| `perf`     | Performance improvement                             |
| `test`     | Adding or correcting tests                          |
| `build`    | Build system, dependencies, or tooling changes      |
| `ci`       | CI config or script changes                         |
| `chore`    | Maintenance, housekeeping, dep bumps                |
| `revert`   | Reverting a previous commit                         |

## Scope (Optional)

A noun describing the affected module. Use parentheses after the type:

```
feat(disko): add LUKS encryption for /dev/sda2
fix(hosts/mars): correct timezone offset
refactor(preservation): extract persistence map to helper
```

Good scopes for this repo: `disko`, `preservation`, `hosts/<name>`, `programs/<name>`, `services/<name>`, `flake`, `deps`.

## Subject

The subject line follows strict rules:

- **Imperative mood** — "add" not "added" or "adds"
- **≤50 characters** — 72 is the hard ceiling
- **No trailing period**
- **Lowercase after the colon-space**
- **Describe what the commit accomplishes**, not what you did or how

```
feat: add email notification support          # good
feat: added feature for email notification    # bad — past tense
fix: fix for the thing that was broken        # bad — vague
```

## Body (Optional — but recommended for non-trivial changes)

Separate from subject with **one blank line**. Explain **what and why**, not **how** (the diff shows how).

- Wrap at **72 characters**
- Use imperative mood
- Answer: *Why was this change necessary? What problem does it solve?*

```
feat(disko): add LUKS encryption for /dev/sda2

The root device was previously unencrypted. This adds LUKS-encrypted
partitioning using a keyfile stored in the initrd, matching the
security posture of the other hosts.
```

## Footers (Optional)

Place after the body (with a blank line separator). Common footers:

| Footer                    | Usage                                |
|---------------------------|--------------------------------------|
| `BREAKING CHANGE:`        | Describes a breaking API/behavior change |
| `Closes #`               | Links to an issue/PR                 |
| `Co-authored-by:`         | Credits another contributor          |
| `Reviewed-by:`            | Code review attribution              |
| `Signed-off-by:`          | DCO sign-off                         |

## Breaking Changes

Two equivalent ways to signal a breaking change:

1. `!` after the type/scope:
   ```
   feat(disko)!: switch partition table from MBR to GPT
   ```

2. `BREAKING CHANGE:` footer:
   ```
   feat(disko): switch partition table from MBR to GPT

   BREAKING CHANGE: existing disks must be reformatted. Backup data
   before deploying.
   ```

Use at least one. Use both when the body needs more explanation.

## Atomic Commits

Each commit should represent **one logical change**. If you're fixing a bug and refactoring unrelated code, make two commits. Atomic commits are easier to review, revert, and understand.

## NixOS Config Examples

```
feat(disko): add LUKS encryption for /dev/sda2
fix(hosts/mars): correct timezone to America/New_York
refactor(preservation): extract persistence map to helper
docs(hosts/mars): add network topology notes
chore(deps): bump nixpkgs-unstable to 2026-06-12
style: reformat with nixfmt
feat(programs/neovim): enable LSP for Rust
fix(services/job-rss): handle empty feed gracefully
```

## Bad Examples (Avoid)

```
update stuff              # too vague
fix                       # no subject
added some things         # past tense, vague
feat: add new feature     # "new feature" is tautological
feat: "add new feature"   # don't quote the subject
```

## Prompting the Agent

When asking the agent to commit, provide:
- What changed (the logical summary)
- Why it was necessary
- Any issue references or breaking change details

The agent will format it into a proper Conventional Commit.
