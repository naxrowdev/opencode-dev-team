# Agentic Dev Team — Equipo de desarrollo con agentes (OpenCode)

**Repo:** `naxrowdev/opencode-dev-team` · **Versión:** `1.0.0` (2026-11-07) — primera versión estable. Ver `CHANGELOG.md` y `VERSION`.

Configuración de proyecto para OpenCode V2 que arma un **equipo completo de desarrollo de software agéntico**: 1 agente primario orquestador (`tech-lead`) + 11 subagentes especializados por rol, con 55 skills curated y vendorizadas en el repo (sin symlinks ni telemetría) y Context7 MCP para documentación vigente. Sin plugins externos: memoria entre sesiones, minimalismo de código y ahorro de tokens se logran con mecanismos nativos (ver abajo).

## Uso (instalar en otro proyecto)

El kit se **inyecta** en un proyecto existente con un solo comando: descarga la última release, copia agentes, skills y config, y siembra un `docs/context/` **vacío** — la memoria del kit (`STATE.md`, `decisions-log.md`) nunca viaja. Guía completa en `docs/guides/installing-into-a-project.md`.

```bash
cd ~/Proyectos/mi-proyecto        # la carpeta de TU proyecto

# previsualizar (no escribe nada) / instalar o actualizar a la última estable
curl -fsSL https://raw.githubusercontent.com/naxrowdev/opencode-dev-team/main/kit/install.sh | sh -s -- --dry-run
curl -fsSL https://raw.githubusercontent.com/naxrowdev/opencode-dev-team/main/kit/install.sh | sh

# versión fijada (tag publicado)
curl -fsSL https://raw.githubusercontent.com/naxrowdev/opencode-dev-team/main/kit/install.sh | sh -s -- --ref v1.0.0
```

El script detecta que corre sin el árbol del kit, baja el tarball de la release a un directorio temporal, instala desde ahí y lo limpia. Requiere `curl` + `tar`; el checksum del tarball es opcional (`--sha256`).

Alternativa sin curl (clonar y ejecutar el instalador local), útil para air-gapped o para revisar el árbol completo:

```bash
git clone git@github.com:naxrowdev/opencode-dev-team.git
sh opencode-dev-team/kit/install.sh --dry-run     # previsualizar
sh opencode-dev-team/kit/install.sh               # instalar
rm -rf opencode-dev-team                          # el clon ya no hace falta
```

> Pegar el ejemplo tal cual con `/ruta/a/mi-proyecto` hace que el instalador corte
> con un error claro — es un guard intencional (ver _si el instalador corta_ en la guía).

El mismo comando de curl **actualiza** un proyecto ya instalado: refresca agentes, skills y guías, conserva `opencode.jsonc`/`AGENTS.md` (con `*.kit-new` si cambiaron) y nunca toca `docs/context/`.

Para **desinstalar**, el instalador deja un manifiesto en `.opencode/kit.json` y el desinstalador borra solo esos archivos:

```bash
cd ~/Proyectos/mi-proyecto
curl -fsSL https://raw.githubusercontent.com/naxrowdev/opencode-dev-team/main/kit/uninstall.sh | sh         # plan, no borra nada
curl -fsSL https://raw.githubusercontent.com/naxrowdev/opencode-dev-team/main/kit/uninstall.sh | sh -s -- --yes
```

Conserva tus agentes y skills propios, `docs/context/` y la config raíz salvo que pases `--purge-context` o `--remove-root-config`. Detalle en `docs/guides/installing-into-a-project.md`.

Para publicar este repo por primera vez, sigue `docs/guides/setup-github.md` (comandos los ejecuta el humano).

El primer agente disponible es `tech-lead`, que orquesta al resto. Conversación típica:

```
> Quiero una app de gestión de turnos para barberías
```

El tech-lead recorrerá: PRD (product-owner) → specs con historias y criterios Gherkin (business-analyst) → contratos y ADRs (architect) → flujos de UI (ux-designer) → plan (tech-lead) → implementación (backend-dev / frontend-dev) → QA (qa-engineer) → revisión (code-reviewer, security-engineer) → entrega (devops-sre, tech-writer). Cada fase le devuelve el control al usuario.

## Estructura

```text
opencode.jsonc        # config V2: MCP Context7 + permisos globales + tool_output/compaction
AGENTS.md             # reglas del repo: stack fijo, pipeline, convenciones
.opencode/
  agents/             # 12 agentes (tech-lead primary + 11 subagents)
  skills/             # 55 skills vendorizadas + adaptadas
  kit.json            # marcador generado por el installer en el proyecto destino
docs/                 # artefactos del pipeline (product/specs/adr/design/plans...)
  context/            # STATE.md + decisions-log.md: memoria entre sesiones
kit/                  # install.sh (modo local y curl) + templates/ + selftest.sh: la herramienta que inyecta el kit
```

## Memoria, minimalismo y tokens (nativo, sin plugins)

- **Contexto entre sesiones**: `docs/context/STATE.md` (estado vivo, **auto-inyectado en todas las sesiones** vía `instructions` en `opencode.jsonc`, ~450 tokens) + `decisions-log.md` (bajo demanda). La skill `context-persistence` define cuándo actualizarlo y la regla de que solo contiene estado factual. Sin `claude-mem` ni costos de API.
- **Menor código**: la skill `code-simplification` es la filosofía del plugin `ponytail` vendida localmente — "el mejor código es el que nunca se escribe", sin inyectar reglas por turno. El `code-reviewer` la usa como rúbrica.
- **Ahorro de tokens**: `tool_output` trunca outputs de herramientas (más de 1000 líneas / 32 KB guarda en disco, recuperable) y `compaction` compacta el historial automáticamente conservando ~25k tokens recientes. Reversible desde `opencode.jsonc`.
- **Modelos por rol (opcional)**: por defecto los 12 roles usan el modelo de la sesión (`/models`). Para repartir modelos, `opencode.jsonc` trae un bloque `agents` comentado con los 12 IDs y la guía `docs/guides/models-per-role.md` explica cómo activarlo, cambiarlo y qué no hace OpenCode (no hay failover automático).
- Plugins considerados y descartados (2026-11-06): `claude-mem`, `ponytail`, `headroom` — evaluados (compatibles con OpenCode V2) pero apartados por costo continuo o dependencias de runtime; requiere ADR para revertir la decisión.

## Stack fijo del equipo

TypeScript · Hono.js · PostgreSQL + Docker · Drizzle ORM/Kit · Better Auth · React 19 (Vite SPA) · React Hook Form · TanStack Query + Axios · Zustand · shadcn/ui + Tailwind · Vitest + Playwright. Ver `AGENTS.md` y la skill `stack-guard` (cambios de stack solo vía ADR humano).

## Seguridad de la configuración

- Permisos por rol en cada agente (`permissions` V2): los roles de producto solo escriben sus docs, los reviewers son solo-lectura, `git push` / `sudo` / `npm publish` / `kubectl delete` / `terraform apply` denegados globalmente, shell pide confirmación, lectura de `.env` pide confirmación.
- Las skills fueron revisadas semánticamente antes de vendorizarse (sin scripts de red, sin exfiltración). Adaptaciones hechas a OpenCode: `!`cmd`` reemplazado por instrucciones shell, `disable-model-invocation` removida donde correspondía, guías con fetch remoto convertidas a copia local (`web-design-guidelines`).
- SkillSpector (scan determinista) no estaba disponible; los veredictos son de revisión semántica manual. Si se obtiene el binario, correr sobre `.opencode/skills/` re-evalúa los hallazgos.

## Skills: qué se vendorizó y de dónde

Fuentes principales (revisadas): obra/superpowers (proceso), mattpocock/skills (tdd, review, domain), deanpeters/product-manager-skills, jeffallan/claude-skills, addyosmani/agent-skills + web-quality-skills, anthropics/skills, vercel-labs/agent-skills, shadcn-ui/ui, honojs/skills, supabase/agent-skills, openai/skills, currents-dev/playwright-best-practices, pproenca/dot-skills, giuseppe-trisciuoglio/developer-kit, wondelai/skills.

Skills custom escritas para este repo: `stack-guard`, `context7-query`, `tanstack-query-zustand`, `better-auth-hono` (adaptación de la referencia NestJS/Next a Hono), `web-design-guidelines` (guidelines vendorizado local), `code-simplification` (ponytail vendorizado), `context-persistence`.
