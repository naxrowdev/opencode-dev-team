# Project State
_Updated: 2026-11-06 · Version: 0.2.1 · by: tech-lead_

## What this is right now

Repositorio kit de un equipo de desarrollo agéntico OpenCode: 1 orquestador (`tech-lead`, morado) + 11 subagentes por rol, 55 skills vendorizadas, Context7 MCP. Desde 0.2.0 el kit es **inyectable**: `kit/install.sh` instala agentes/skills/config en un proyecto destino y siembra `docs/context/` vacío — la memoria de este repo no viaja.

## Current state

- Built: v0.2.1 — el instalador valida el target ANTES de crear nada en disco: guard de paths placeholder pegados desde la documentación (`/ruta/...`, `/path/to/...`, `/your/...`), error amable de `mkdir`, y flujo principal = `git clone` del kit **dentro del proyecto** + `sh opencode-dev-team/kit/install.sh` desde la raíz (sin `cd` al clon, sin argumentos) con hint de limpieza (`rm -rf opencode-dev-team`) y guard que corta si el destino ES el clon. Origen: primer caso real de uso (bloque del README pegado verbatim → `mkdir: Permission denied` y proyecto destino vacío). Selftest 50/50 en verde.
- First real project: `~/Proyectos/web-opencode-dev-team` instalado con éxito (12 agentes, 55 skills, `docs/context/` sembrado vacío); el pipeline completo aún no se validó ahí.
- In progress: nada.
- Blocked / waiting user: push 0.2.1 + tag `v0.2.1` (`docs/guides/setup-github.md`); LICENSE pendiente de elección.
- En revisión del tech-lead: upgrades con hash/3-way diff, submodule y `npx` siguen como candidato para 0.3.

## Nota técnica (contexto de herramientas)

- Memoria entre sesiones: **sin plugins** — `STATE.md` auto-inyectado (solo estado factual) + `decisions-log.md` bajo demanda (skill `context-persistence`).
- Minimalismo de código: skill `code-simplification` (filosofía ponytail vendorizada); la audita `code-reviewer`.
- Ahorro de tokens: `tool_output` (trunca >1000 líneas / 32 KB, guarda en disco) + `compaction` (auto, conserva ~25k tokens recientes).
- Plugins descartados (2026-11-06): `claude-mem` (costo continuo + Bun), `ponytail` (inyección por turno), `headroom` (proxy Python). Re-decidible vía ADR.

## Next steps

1. Usuario: push a GitHub + tag `v0.2.1` (comandos en `docs/guides/setup-github.md`).
2. Validar el pipeline completo (`PRD → specs → diseño → plan → implementación → QA → review → entrega`) en `web-opencode-dev-team`; tras validarlo, promover a `1.0.0`.
3. Si algún proyecto externaliza docs: descomentar `references` en `opencode.jsonc`.
