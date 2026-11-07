# Project State
_Updated: 2026-11-06 · Version: 0.2.0 · by: tech-lead_

## What this is right now

Repositorio kit de un equipo de desarrollo agéntico OpenCode: 1 orquestador (`tech-lead`, morado) + 11 subagentes por rol, 55 skills vendorizadas, Context7 MCP. Desde 0.2.0 el kit es **inyectable**: `kit/install.sh` instala agentes/skills/config en un proyecto destino y siembra `docs/context/` vacío — la memoria de este repo no viaja.

## Current state

- Built: config completa + kit inyectable (`kit/{install.sh,selftest.sh,include.txt,exclude.txt,templates/}`); selftest 34/34 en verde; guía `docs/guides/installing-into-a-project.md` (reemplaza la receta manual `cp -r` rota, que no copiaba `docs/`).
- In progress: nada — listo para publicar 0.2.0.
- Blocked / waiting user: push 0.2.0 + tag `v0.2.0` (`docs/guides/setup-github.md`); LICENSE pendiente de elección.
- En revisión del tech-lead: la config raíz del destino se instala create-if-absent (`*.kit-new` si ya existía); upgrades con hash/3-way diff, submodule y `npx` quedaron fuera de 0.2.0 y son candidato para 0.3.

## Nota técnica (contexto de herramientas)

- Memoria entre sesiones: **sin plugins** — `STATE.md` auto-inyectado (solo estado factual) + `decisions-log.md` bajo demanda (skill `context-persistence`).
- Minimalismo de código: skill `code-simplification` (filosofía ponytail vendorizada); la audita `code-reviewer`.
- Ahorro de tokens: `tool_output` (trunca >1000 líneas / 32 KB, guarda en disco) + `compaction` (auto, conserva ~25k tokens recientes).
- Plugins descartados (2026-11-06): `claude-mem` (costo continuo + Bun), `ponytail` (inyección por turno), `headroom` (proxy Python). Re-decidible vía ADR.

## Next steps

1. Usuario: push a GitHub + tag `v0.1.0` (comandos en `docs/guides/setup-github.md`).
2. Primer proyecto real: arrancar con tech-lead siguiendo el pipeline de `AGENTS.md`; tras validarlo, promover a `1.0.0`.
3. Si algún proyecto externaliza docs: descomentar `references` en `opencode.jsonc`.
