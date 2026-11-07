# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `kit/selftest.sh` asserts that the prose installed into a target project contains
  no voseo, so the Spanish convention fails the check instead of waiting for a
  review comment.
- `docs/adr/0001-use-neutral-spanish-in-kit-documentation.md` records the language
  convention and its rationale.

### Changed

- The kit's prose (agent prompts, `README.md`, `AGENTS.md`, the installation guide,
  and the installer/selftest messages) now uses **neutral Spanish** instead of
  Rioplatense voseo. Second person "tú" and standard imperative forms replace
  forms such as "Sos", "escribís", "podés", "usá" and "mergeá". Git and CLI
  vocabulary (`push`, `commit`, `merge`) stays in English; "deploy" in prose is
  now "despliegue".
- `AGENTS.md` and the `tech-writer`, `product-owner`, `business-analyst` and
  `ux-designer` prompts now state the neutral-Spanish rule, so new documentation
  inherits it.

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
