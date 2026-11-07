# Decisions Log (append-only)

Cada entrada: fecha — decisión, no alternativas. 2-4 líneas: quién decide, argumento principal, archivos afectados.

---

## 2026-11-06 — Kit inyectable con contexto vacío (`kit/install.sh`), not clonar el repo ni submodule

Tech-lead con el usuario: el kit se instala en proyectos destino vía `kit/install.sh` (vendored — los archivos quedan commiteados en el proyecto), sembrando `docs/context/` vacío desde `kit/templates/` para que la memoria del kit nunca viaje. Config raíz create-if-absent con `*.kit-new`; upgrades con hash/3-way diff, submodule y `npx` quedaron fuera de 0.2.0. Archivos: `kit/`, `docs/guides/installing-into-a-project.md`, `README.md`, `docs/guides/setup-github.md`, `AGENTS.md`, `VERSION`, `CHANGELOG.md`.

## 2026-11-06 — Repo `opencode-dev-team` (naxrowdev), not `agentic-dev-team` / `agentic-forge`

Tech-lead con el usuario: el nombre del repo prioriza discoverability en el ecosistema OpenCode ("opencode-dev-team", siendo honesto de que la config depende de OpenCode V2). La marca "Agentic Dev Team" queda como título del README. Descripción en castellano + keywords EN. Archivos: `README.md`, `docs/guides/setup-github.md`, `docs/context/STATE.md`.

## 2026-11-06 — Pre-release 0.1.0, not 1.0.0 straight away

Tech-lead con el usuario: se corta la primera publicación como 0.1.0 (pre-release) — la promoción a 1.0.0 queda condicionada a validar el equipo en un proyecto real. Archivos: `CHANGELOG.md`, `VERSION`, `README.md`, tag `v0.1.0` (lo crea el usuario al subir).

## 2026-11-06 — `STATE.md` auto-inyectado vía `instructions`, not lectura manual

Tech-lead decide: `docs/context/STATE.md` entra en el config como instruction ambient (`"instructions": ["docs/context/STATE.md"]`) para que el contexto llegue a TODAS las sesiones sin depender del modelo (~450 tokens, verificado vivo). Contrapartida de seguridad: STATE.md solo estado factual (skill `context-persistence`); regla ADR requerida para sacarlo. Archivos: `opencode.jsonc`, `AGENTS.md`, `.opencode/agents/tech-lead.md`, skill `context-persistence`, `docs/context/README.md`.

## 2026-11-06 — Equipo 12 agentes + Config nativa, no plugins externos, not `claude-mem`/`ponytail`/`headroom` plugins

Tech-lead con el usuario decide: en lugar de plugins con costo continuo o dependencias nuevas de runtime, se vendoriza la *filosofía* (`code-simplification`), la memoria pasa por repo (`context-persistence`) y el ahorro de tokens se configura nativamente (tool_output + compaction). Archivos: `opencode.jsonc`, `.opencode/skills/{code-simplification,context-persistence}/`, `docs/context/`.

## 2026-11-06 — Stack fijo leyendo `stack-guard`, con 53→55 skills

Skills vendorizadas + adaptadas desde 15 repos abiertos con revisión semántica; custom: stack-guard, context7-query, tanstack-query-zustand, better-auth-hono, web-design-guidelines. El stack es fijo; cambios solo vía ADR aprobado por el usuario. Archivos: `.opencode/skills/`, `AGENTS.md`.
