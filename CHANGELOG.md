# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
