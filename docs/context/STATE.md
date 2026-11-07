# Project State
_Updated: 2026-11-07 · Version: 0.2.1 · by: tech-lead_

## What this is right now

Repositorio kit de un equipo de desarrollo agéntico OpenCode: 1 orquestador (`tech-lead`, morado) + 11 subagentes por rol, 55 skills vendorizadas, Context7 MCP. Desde 0.2.0 el kit es **inyectable**: `kit/install.sh` instala agentes/skills/config en un proyecto destino y siembra `docs/context/` vacío — la memoria de este repo no viaja.

## Current state

- Built: v0.2.1 — el instalador valida el target ANTES de crear nada en disco: guard de paths placeholder pegados desde la documentación (`/ruta/...`, `/path/to/...`, `/your/...`), error amable de `mkdir`, y flujo principal = `git clone` del kit **dentro del proyecto** + `sh opencode-dev-team/kit/install.sh` desde la raíz (sin `cd` al clon, sin argumentos) con hint de limpieza (`rm -rf opencode-dev-team`) y guard que corta si el destino ES el clon. Origen: primer caso real de uso (bloque del README pegado verbatim → `mkdir: Permission denied` y proyecto destino vacío). Selftest 51/51 en verde.
- First real project: `~/Proyectos/web-opencode-dev-team` — el estado anterior ("instalado con éxito") era **falso**: la carpeta no existía. Instalado de cero el 2026-11-07 (12 agentes, 55 skills, `docs/context/` sembrado vacío) y ahí se construyó la web de presentación del kit con el pipeline del equipo: PRD → diseño+copy → plan → implementación → review → docs. Etapas omitidas por diseño (la landing no tiene API ni persistencia): business-analyst, architect de API y backend-dev. Quedan pendientes los criterios de usabilidad con personas.
- Bug corregido (2026-11-07, sin publicar): el orden de las reglas de permisos en los archivos de agente anulaba la escritura de todos los subagentes (`edit *: deny` después de los `allow` por carpeta; gana la última regla que coincide).
- Idioma del kit (2026-11-07, sin publicar): la prosa (12 prompts de agente, `README.md`, `AGENTS.md`, guía de instalación y mensajes del instalador/selftest) pasa a español neutro, sin voseo — ADR `docs/adr/0001-use-neutral-spanish-in-kit-documentation.md`. `kit/selftest.sh` asserta que la prosa instalada no tenga voseo. Las 55 skills vendorizadas siguen en inglés (sin cambios).
- Entrega de cambios (2026-11-07, sin publicar): al cerrar cada cambio el agente entrega el bloque de comandos de commit/push/tag correspondientes y **no lo ejecuta** (`git push` sigue en `deny` global). Sección "Entrega de cambios" en `AGENTS.md`, replicada en los prompts de `tech-lead`, `devops-sre` y `tech-writer`.
- In progress: nada.
- Blocked / waiting user: push 0.2.1 + tag `v0.2.1` (`docs/guides/setup-github.md`); LICENSE pendiente de elección; publicar la corrección de permisos (v0.2.2) y el cambio de idioma neutro cuando el usuario defina el remoto y la versión (versionado diferido por decisión del usuario).
- En revisión del tech-lead: upgrades con hash/3-way diff, submodule y `npx` siguen como candidato para 0.3.

## Nota técnica (contexto de herramientas)

- Memoria entre sesiones: **sin plugins** — `STATE.md` auto-inyectado (solo estado factual) + `decisions-log.md` bajo demanda (skill `context-persistence`).
- Minimalismo de código: skill `code-simplification` (filosofía ponytail vendorizada); la audita `code-reviewer`.
- Ahorro de tokens: `tool_output` (trunca >1000 líneas / 32 KB, guarda en disco) + `compaction` (auto, conserva ~25k tokens recientes).
- Plugins descartados (2026-11-06): `claude-mem` (costo continuo + Bun), `ponytail` (inyección por turno), `headroom` (proxy Python). Re-decidible vía ADR.

## Next steps

1. Usuario: push a GitHub + tag `v0.2.1` (comandos en `docs/guides/setup-github.md`).
2. Validar el pipeline completo (`PRD → specs → diseño → plan → implementación → QA → review → entrega`) en `web-opencode-dev-team`: la cadena PRD → diseño → plan → implementación → review → docs ya se ejecutó (2026-11-07); faltan business-analyst y architect de API, que no aplican a una landing sin backend. La promoción a `1.0.0` sigue condicionada a esa validación.
3. Publicar la corrección de permisos de agentes (v0.2.2) cuando el usuario defina el remoto.
4. Si algún proyecto externaliza docs: descomentar `references` en `opencode.jsonc`.
