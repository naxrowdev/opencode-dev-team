# Project State
_Updated: 2026-11-06 · Version: 0.1.0 (pre-release) · by: tech-lead_

## What this is right now

Repositorio de configuración de un equipo de desarrollo agéntico OpenCode: 1 orquestador (`tech-lead`, morado) + 11 subagentes por rol, 55 skills vendorizadas/custom, Context7 MCP conectado. No hay código de aplicación todavía.

## Current state

- Built: configuración completa (`.opencode/agents/`, `.opencode/skills/`, `opencode.jsonc`, `AGENTS.md`, `docs/`), lista para publicar (`.gitignore`, `CHANGELOG.md`, `VERSION`, guía de GitHub).
- **Repo publicado**: `github.com/naxrowdev/opencode-dev-team` (v0.1.0, tag `v0.1.0` que el usuario crea al push).
- Contexto entre sesiones: este archivo se auto-inyecta en todas las sesiones (config `instructions`); verificá contra el repo antes de actuar.
- In progress: espera al usuario — ejecutar `git init/push` + tag `v0.1.0` según `docs/guides/setup-github.md`.
- Blocked / waiting user: push, tag y LICENSE (elección: MIT sugerida).

## Nota técnica (contexto de herramientas)

- Memoria entre sesiones: **sin plugins** — `STATE.md` auto-inyectado (solo estado factual) + `decisions-log.md` bajo demanda (skill `context-persistence`).
- Minimalismo de código: skill `code-simplification` (filosofía ponytail vendorizada); la audita `code-reviewer`.
- Ahorro de tokens: `tool_output` (trunca >1000 líneas / 32 KB, guarda en disco) + `compaction` (auto, conserva ~25k tokens recientes).
- Plugins descartados (2026-11-06): `claude-mem` (costo continuo + Bun), `ponytail` (inyección por turno), `headroom` (proxy Python). Re-decidible vía ADR.

## Next steps

1. Usuario: push a GitHub + tag `v0.1.0` (comandos en `docs/guides/setup-github.md`).
2. Primer proyecto real: arrancar con tech-lead siguiendo el pipeline de `AGENTS.md`; tras validarlo, promover a `1.0.0`.
3. Si algún proyecto externaliza docs: descomentar `references` en `opencode.jsonc`.
