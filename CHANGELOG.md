# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-11-07

### Added

- `kit/uninstall.sh` removes the kit from a project safely: it reads the install manifest
  (`.opencode/kit.json` → `"files"`) and deletes exactly those paths, then removes
  directories left empty with `rmdir` (never `rm -rf`). Default behaviour is **plan
  only**; `--yes` applies it, `--dry-run` is an explicit alias, `--purge-context` and
  `--remove-root-config` opt into deleting the seeded project memory and the root config.
  Manifest paths are validated (relative, no `..`), invalid ones are skipped with a
  warning, the kit repo is refused as a target, and installations without a manifest are
  refused with a "reinstall first" message instead of guessing.
- `kit/install.sh` now records a manifest of every kit-owned file it writes (`"files"` in
  `.opencode/kit.json`, computed from the source tree that `include.txt` selects, so
  files the project added are never listed). The seeded `docs/context/STATE.md` /
  `decisions-log.md` and the root config stay out of it.
- `docs/adr/0003-kit-manifest-and-uninstall.md` records the manifest contract, why
  heuristics and `rm -rf` were rejected, and the state of pre-1.0.0 installations.
- `kit/install.sh` now self-bootstraps, so installing and updating are one command:
  `curl -fsSL <url>/kit/install.sh | sh`. When the kit tree is not next to `$0`, the script
  resolves the latest GitHub Release (via the `/releases/latest` redirect, no API call),
  downloads `codeload.github.com/<repo>/tar.gz/<ref>`, verifies an optional `--sha256`,
  extracts into `mktemp -d`, runs that copy with the same arguments, and cleans up. Mode is
  detected from the assets being present, so the extracted copy cannot recurse. New
  curl-only flags: `--ref`, `--sha256`, `--tarball` (offline), `--repo` (forks); local mode
  rejects them with an explicit message. `.opencode/kit.json` gains `ref`, and `source`
  comes from `KIT_SOURCE_URL` in curl mode.
- `docs/adr/0002-self-bootstrapping-installer.md` records the decision, the latest-stable
  resolution without the GitHub API, the trust mitigations, and the alternatives rejected
  (separate bootstrap script, base64 payload, `npx`, API lookup, release assets).
- `kit/selftest.sh` grows to 109 assertions: the curl-mode section builds a GitHub-shaped
  tarball of the working tree and drives the real piped path through
  `ODT_TARBALL_URL=file://` (install, provenance, `--dry-run`, good/bad checksum, tarball
  without the kit, `--help`, and curl-only flags rejected in local mode), and the uninstall
  section covers the manifest contents, plan-only behaviour, preservation of user agents
  and skills, project memory and root config, both optional flags, the legacy-marker
  refusal, path-traversal skipping, the kit-repo guard, and a full
  install → uninstall → install cycle.
- Per-role models are documented as **optional and user-owned**, never a kit default:
  `opencode.jsonc` ships a commented `agents` block with the 12 role IDs, `AGENTS.md`
  gains a row in the native-mechanisms table, and the new
  `docs/guides/models-per-role.md` covers activation, tier suggestions, hot reload,
  the `/models` scope, and the absence of automatic failover. `kit/include.txt` now
  installs the guide into target projects and `kit/selftest.sh` asserts that the guide
  travels and that the example block stays commented (no active `agents` key).
- Every agent now delivers the `commit`, `push` and `tag` commands for the change it
  just made, and stops there: the commands go in the report, the user runs them. This
  is not a preference — `git push` was already globally denied in `opencode.jsonc`, so
  the delivery can only be commands. The rule lives in `AGENTS.md` under "Entrega de
  cambios" and is mirrored in the `tech-lead`, `devops-sre` and `tech-writer` prompts.
- `kit/selftest.sh` asserts that the prose installed into a target project contains
  no voseo, so the Spanish convention fails the check instead of waiting for a
  review comment.
- `docs/adr/0001-use-neutral-spanish-in-kit-documentation.md` records the language
  convention and its rationale.

### Changed

- The documented way to install and update the kit is now the curl one-liner; the clone
  flow stays documented and tested as the air-gapped alternative. `docs/guides/setup-github.md`
  now requires a GitHub Release per tag, because "latest" is resolved from
  `/releases/latest`. The installation guide gained the update semantics (kit-owned files
  refreshed, root config preserved as `*.kit-new`, context untouched, removed files not
  pruned).
- The kit's prose (agent prompts, `README.md`, `AGENTS.md`, the installation guide,
  and the installer/selftest messages) now uses **neutral Spanish** instead of
  Rioplatense voseo. Second person "tú" and standard imperative forms replace
  forms such as "Sos", "escribís", "podés", "usá" and "mergeá". Git and CLI
  vocabulary (`push`, `commit`, `merge`) stays in English; "deploy" in prose is
  now "despliegue".
- `AGENTS.md` and the `tech-writer`, `product-owner`, `business-analyst` and
  `ux-designer` prompts now state the neutral-Spanish rule, so new documentation
  inherits it.

_[1.0.0]: primera versión estable del kit. Queda pendiente validar el one-liner de curl
contra una GitHub Release publicada (hoy se prueba con tarballs locales)._

## [0.2.1] - 2026-11-06

### Fixed

- `kit/install.sh` refuses documentation-placeholder targets (`/ruta/...`, `/path/to/...`,
  `/your/...`) with an explicit message **before** creating anything on disk. First
  reported by a real usage case: pasting the README example verbatim made the installer
  attempt `/ruta/a/mi-proyecto`, die on a raw `mkdir: Permission denied`, and never touch
  the user's project.
- `mkdir` failures are reported by the installer itself (`no se pudo crear el destino ...`)
  instead of leaking the raw coreutils error.

### Changed

- The documented primary flow is now: `cd` to the project, `git clone` the kit **inside**
  the project, and run `sh opencode-dev-team/kit/install.sh` from the project root (no
  `cd` into the clone, no target argument). The installer detects a kit clone sitting
  inside the target and prints a `rm -rf` cleanup hint when it finishes; a fresh guard
  refuses to run from inside the clone itself (`el destino es el propio clon del kit`).
  Cloning elsewhere + passing `TARGET_DIR` stays as the documented alternative.
- README and the install guide now use a `PROYECTO=$HOME/...` variable with an explicit
  replace-the-path note, a troubleshooting table (placeholder targets, mkdir failures,
  foreign `.opencode/`), and a `git init` reminder for non-repo destinations.
- `kit/selftest.sh` grows to 50 assertions (placeholder guard, friendly mkdir error,
  the no-argument current-directory flow, and the clone-inside-the-project flow).

## [0.2.0] - 2026-11-06

### Added

- `kit/install.sh`: injects the dev team into a target project — copies kit-owned files
  (`.opencode/agents`, `.opencode/skills`, `docs/*/README.md`), seeds an **empty** project
  context from `kit/templates/`, and never carries over this repository's own state.
- `kit/include.txt` / `kit/exclude.txt`: explicit, self-documenting manifest of what travels
  and what never does; the installer validates that no included path matches an exclusion.
- `kit/templates/`: `STATE.md` + `decisions-log.md` (empty, placeholder-resolved on install)
  and a project-appropriate `.gitignore` (without this repo's kit-only ignore lines).
- `kit/selftest.sh`: 34 assertions — fresh install carries no kit history, context is
  write-once across re-runs, pre-existing project config is preserved and offered as
  `*.kit-new`, guards refuse installing into the kit repo itself or over a foreign `.opencode/`.
- Install marker `.opencode/kit.json` (kit version, date, source) in the target project.
- Guide `docs/guides/installing-into-a-project.md` (replaces the broken manual `cp -r`
  recipe, which copied no `docs/` tree and left `instructions` pointing at a missing file).

### Changed

- `AGENTS.md` turned project-agnostic: skill-count and vendoring provenance removed (they
  live in this repo's README and each skill's frontmatter), the plugins-decision line is
  now a rule instead of kit history.
- `docs/guides/setup-github.md` and `README.md` now point to `kit/install.sh` for
  distributing to other projects; `VERSION` bumped 0.1.0 → 0.2.0.

_[0.2.0]: el kit ya no contamina el contexto de los proyectos que lo consumen._

## [0.1.0] - 2026-11-06

### Added

- Agentic dev team config for OpenCode V2: 12 agents (`tech-lead` primary, purple, + 11 role subagents with distinct colors), global and per-agent permission rules, `default_agent: "tech-lead"`.
- 55 skills under `.opencode/skills/`: 48 vendored from reviewed open repos (adapted for OpenCode: no `!`cmd`` injection, no remote fetches) + 7 custom (`stack-guard`, `context7-query`, `tanstack-query-zustand`, `better-auth-hono`, `web-design-guidelines`, `code-simplification` [ponytail vendored], `context-persistence`).
- Context7 MCP (remote) connected for library docs lookup; `AGENTS.md` forbids inventing API signatures.
- Native token savings in `opencode.jsonc`: `tool_output` truncation (1000 lines / 32 KB) + automatic `compaction` (keep 25k tokens, 15% buffer).
- Cross-session memory without plugins: `docs/context/STATE.md` auto-injected as ambient instructions (config `instructions`) + `decisions-log.md` on demand, driven by the `context-persistence` skill.
- Minimalism rubric: `code-simplification` skill (ponytail philosophy), audited by `code-reviewer`.
- Project pipeline folders: `docs/{context,product,specs,adr,design,plans,guides,security}/`.
- `.env.example` (placeholders only), `.gitignore` (env, builds, test artifacts), GitHub setup guide (`docs/guides/setup-github.md`).

_[0.1.0]: pre-release — se promueve a 1.0.0 tras validar el equipo en un proyecto real._
