# Project State
_Updated: 2026-11-07 · Version: 1.0.0 · by: tech-lead_

## What this is right now

Repositorio kit de un equipo de desarrollo agéntico OpenCode: 1 orquestador (`tech-lead`, morado) + 11 subagentes por rol, 55 skills vendorizadas, Context7 MCP. Desde 0.2.0 el kit es **inyectable**: `kit/install.sh` instala agentes/skills/config en un proyecto destino y siembra `docs/context/` vacío — la memoria de este repo no viaja.

## Current state

- Built: v1.0.0 (2026-11-07) — primera versión estable. El instalador valida el target ANTES de crear nada en disco (guard de paths placeholder pegados desde la documentación, error amable de `mkdir`, guard si el destino es el clon). Instalación y actualización = un solo `curl -fsSL <url>/kit/install.sh | sh` (auto-bootstrap desde la última GitHub Release); `git clone` queda como alternativa air-gapped. Desinstalación = `kit/uninstall.sh` sobre el manifiesto de `kit.json` (plan por defecto, `--yes`, `rmdir`-only). Selftest 109/109 en verde.
- First real project: `~/Proyectos/web-opencode-dev-team` — el estado anterior ("instalado con éxito") era **falso**: la carpeta no existía. Instalado de cero el 2026-11-07 (12 agentes, 55 skills, `docs/context/` sembrado vacío) y ahí se construyó la web de presentación del kit con el pipeline del equipo: PRD → diseño+copy → plan → implementación → review → docs. Etapas omitidas por diseño (la landing no tiene API ni persistencia): business-analyst, architect de API y backend-dev. Quedan pendientes los criterios de usabilidad con personas.
- Bug corregido (2026-11-07, incluido en 1.0.0): el orden de las reglas de permisos en los archivos de agente anulaba la escritura de todos los subagentes (`edit *: deny` después de los `allow` por carpeta; gana la última regla que coincide).
- Idioma del kit (2026-11-07, incluido en 1.0.0): la prosa (12 prompts de agente, `README.md`, `AGENTS.md`, guía de instalación y mensajes del instalador/selftest) pasa a español neutro, sin voseo — ADR `docs/adr/0001-use-neutral-spanish-in-kit-documentation.md`. `kit/selftest.sh` asserta que la prosa instalada no tenga voseo. Las 55 skills vendorizadas siguen en inglés (sin cambios).
- Entrega de cambios (2026-11-07, incluido en 1.0.0): al cerrar cada cambio el agente entrega el bloque de comandos de commit/push/tag correspondientes y **no lo ejecuta** (`git push` sigue en `deny` global). Sección "Entrega de cambios" en `AGENTS.md`, replicada en los prompts de `tech-lead`, `devops-sre` y `tech-writer`.
- Modelos por rol (2026-11-07, incluido en 1.0.0): **opcionales, no es un default**. `opencode.jsonc` trae un bloque `agents` comentado con los 12 IDs (verificado: `opencode debug agents` resuelve `agents.<rol>.model` sobre el frontmatter Markdown), `AGENTS.md` suma una fila en la tabla de mecanismos nativos y `docs/guides/models-per-role.md` explica activación, tiers sugeridos, cambio en caliente y la ausencia de failover automático. `kit/include.txt` instala la guía y `kit/selftest.sh` asserta que viaja y que el bloque sigue comentado.
- Instalación por curl (2026-11-07, incluido en 1.0.0): `kit/install.sh` se auto-bootstrapea — si no encuentra el árbol junto a `$0`, resuelve la última GitHub Release por el redirect de `/releases/latest` (sin API), baja `codeload.../tar.gz/<ref>`, verifica `--sha256` opcional, instala desde un temp y limpia. Flags curl-only: `--ref`, `--sha256`, `--tarball` (offline), `--repo`; en modo local se rechazan con mensaje. `kit.json` suma `ref`. El flujo clone sigue existiendo para air-gapped. ADR `docs/adr/0002-self-bootstrapping-installer.md`. La sección curl del selftest es hermética (`ODT_TARBALL_URL=file://`).
- Desinstalación (2026-11-07, incluido en 1.0.0): `install.sh` escribe un **manifiesto** (`"files"` en `.opencode/kit.json`, 450 rutas enumeradas del árbol origen; quedan fuera la memoria sembrada y la config raíz). `kit/uninstall.sh` es autocontenido (sin red ni árbol del kit, funciona piped): plan por defecto, `--yes`, `--dry-run`, `--purge-context`, `--remove-root-config`; solo borra rutas del manifiesto validadas (relativas, sin `..`), usa `rmdir` (nunca `rm -rf`), rechaza el repo del kit y se niega ante instalaciones sin manifiesto. ADR `docs/adr/0003-kit-manifest-and-uninstall.md`. Selftest **109/109**.
- In progress: nada.
- Blocked / waiting user: **publicar 1.0.0** — push, tag `v1.0.0` y **GitHub Release** por tag (`docs/guides/setup-github.md`); sin release, el one-liner de curl no resuelve "latest" y el modo curl solo está validado con tarballs locales. LICENSE pendiente de elección.
- Deuda conocida: instalaciones previas a 1.0.0 (`~/Proyectos/web-opencode-dev-team`) no tienen manifiesto; hay que reinstalar una vez antes de poder desinstalar.
- En revisión del tech-lead: upgrades con hash/3-way diff, submodule y `npx` siguen como candidato post-1.0.

## Nota técnica (contexto de herramientas)

- Memoria entre sesiones: **sin plugins** — `STATE.md` auto-inyectado (solo estado factual) + `decisions-log.md` bajo demanda (skill `context-persistence`).
- Minimalismo de código: skill `code-simplification` (filosofía ponytail vendorizada); la audita `code-reviewer`.
- Ahorro de tokens: `tool_output` (trunca >1000 líneas / 32 KB, guarda en disco) + `compaction` (auto, conserva ~25k tokens recientes).
- Plugins descartados (2026-11-06): `claude-mem` (costo continuo + Bun), `ponytail` (inyección por turno), `headroom` (proxy Python). Re-decidible vía ADR.

## Next steps

1. Usuario: publicar la 1.0.0 — push, tag `v1.0.0` y **GitHub Release** (comandos en `docs/guides/setup-github.md`).
2. Validar el one-liner real de curl contra la Release publicada y, en `web-opencode-dev-team`, reinstalar una vez (genera manifiesto) y probar `uninstall.sh`.
3. Validar las etapas que faltan del pipeline (`business-analyst`, `architect` de API) en un proyecto con backend: la landing sin API no las ejercita.
4. Si algún proyecto externaliza docs: descomentar `references` en `opencode.jsonc`.
