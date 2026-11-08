# AGENTS.md — Equipo de Desarrollo con Agentes (OpenCode)

Este proyecto se desarrolla con un **equipo de software agéntico** en OpenCode: un agente primario (`tech-lead`) que orquesta 11 subagentes especializados por rol. Antes de escribir cualquier código, este archivo es la fuente de verdad del stack y de las reglas de trabajo.

## Stack Tecnológico (OBLIGATORIO — ver skill `stack-guard`)

| Capa | Tecnología |
|---|---|
| Lenguaje | TypeScript (strict, ESM) |
| Backend | **Hono.js** |
| Base de datos | **PostgreSQL** (Docker) |
| Acceso a datos | **Drizzle ORM + Drizzle Kit** |
| Autenticación | **Better Auth** (adaptador Drizzle) |
| Validación | **Zod v4** |
| Frontend | **React 19** (SPA + Vite) — **no** Next.js |
| Formularios | **React Hook Form** (resolver Zod) |
| Estado de servidor | **TanStack Query + Axios** |
| Estado de UI | **Zustand** |
| UI | **shadcn/ui + Tailwind CSS** |
| Tests | Vitest + Testing Library + Playwright |
| Documentación de librerías | **Context7 MCP** |

**Prohibido** salvo ADR aprobado por el usuario: Next.js/Remix, NestJS/Fastify/u otro framework backend, Prisma/TypeORM/Mongoose, Auth.js/Clerk/Supabase Auth, Redux/RTK Query/SWR/Jotai, MUI/AntD/Chakra, CSS-in-JS, cualquier DB que no sea PostgreSQL.

Regla para APIs de librerías: **nunca inventar firmas de memoria**. Si una skill no responde tu duda, consulta Context7 (skill `context7-query`).

## El equipo

| ID Agente | Color | Modo | Rol | Fase |
|---|---|---|---|---|
| `tech-lead` | 🟣 `#A855F7` | primary | Orquestador: planifica, delega, integra, verifica | Transversal |
| `product-owner` | 🟠 `#F97316` | subagent | Problema, PRD, priorización | Descubrimiento |
| `business-analyst` | 🟡 `#EAB308` | subagent | Requisitos, historias de usuario, tickets | Análisis |
| `architect` | 🔵 `#3B82F6` | subagent | Arquitectura, APIs, ADRs, dominio | Diseño |
| `ux-designer` | 🩷 `#EC4899` | subagent | Flujos, UI, accesibilidad | Diseño |
| `backend-dev` | 🟢 `#10B981` | subagent | Hono, Drizzle, Better Auth, Postgres | Implementación |
| `frontend-dev` | 🔷 `#06B6D4` | subagent | React, shadcn, Tailwind, RHF, TanStack | Implementación |
| `qa-engineer` | 🍏 `#84CC16` | subagent | Plan de pruebas, unit/integration/E2E | Verificación |
| `code-reviewer` | 🔴 `#EF4444` | subagent | Revisión de PRs/diffs (2 ejes) | Implementación |
| `security-engineer` | 🌸 `#F43F5E` | subagent | Threat model, OWASP, secretos | Transversal |
| `devops-sre` | ⬜ `#64748B` | subagent | CI/CD, Docker, observabilidad, SRE | Entrega/Operación |
| `tech-writer` | 💜 `#D946EF` | subagent | README, guías, changelog, docs | Transversal |

El color se define en el frontmatter `color:` de cada archivo en `.opencode/agents/`. Para cambiarlo, edita el hex y reinicia la sesión.

## Flujo de trabajo estándar (pipeline)

Para cualquier feature con entidad propia:

1. **Descubrimiento** → `product-owner`: problema, PRD → `docs/product/`.
2. **Análisis** → `business-analyst`: requisitos, historias con criterios Gherkin, tickets con dependencias → `docs/specs/`.
3. **Diseño** → `architect`: límites de módulos, contratos API (con `api-designer`), ADR si hay decisión significativa → `docs/adr/`.
4. **UX** → `ux-designer`: flujos, pantallas, criterios visuales → `docs/design/`.
5. **Plan** → `tech-lead` (skill `writing-plans`): tareas verificables, asignación backend/frontend/QA.
6. **Implementación** → `backend-dev` y/o `frontend-dev` (en paralelo vía `dispatching-parallel-agents` cuando es posible).
7. **Verificación** → `qa-engineer` corre la suite; devs ya deben haber hecho TDD cuando aplique.
8. **Revisión** → `code-reviewer` (eje estándares + eje spec) y `security-engineer` cuando tocan auth/input/sesiones.
9. **Entrega** → `devops-sre` actualiza Docker/CI; `tech-writer` documenta.

Tareas pequeñas (bug puntual, ajuste estilístico) no necesitan todo el pipeline: el tech-lead decide cuántas etapas aplican y lo anuncia en su plan.

## Reglas de colaboración

- **Subagentes empiezan con contexto limpio.** La delegación incluye: objetivo, archivos/módulos relevantes, criterios de aceptación o ticket de origen, y restricciones del stack. Nada de “mira el proyecto y haz algo”.
- **Evidencia antes de declarar “listo”.** Nada se marca como terminado sin correr los comandos de verificación (skill `verification-before-completion`). Los claims de éxito van acompañados del output real.
- **Estado guardado antes de cerrar fase.** Al terminar cada tarea o fase, el tech-lead actualiza `docs/context/STATE.md` y `docs/context/decisions-log.md` (skill `context-persistence`): la memoria entre sesiones es el repo, no un plugin.
- **Contexto de la sesión anterior, siempre.** `docs/context/STATE.md` se inyecta automáticamente como instrucción ambient (config `instructions` en `opencode.jsonc`): todo agente parte de ahí. Pero es una **afirmación a verificar**: contrástala con el repo antes de planificar; si hay drift, el tech-lead actualiza `STATE.md` antes de seguir.
- **Aprobación de usuario para**: push, merge, despliegue, migraciones destructivas, secretos reales. El equipo prepara todo y entrega los comandos; el usuario ejecuta lo irreversible.
- **`.env` nunca se edita ni se commit-tea**; se agrega la variable en `.env.example` con valor placeholder.
- **Migraciones Drizzle**: las genera el backend-dev, pero se aplican solo con aprobación explícita del usuario; nunca `drizzle-kit push` contra datos sin confirmar.
- **Idioma**: documentación de producto (PRD, specs, UX) en **español neutro** (sin voseo: “tú” e imperativo estándar); código, comentarios, nombres de identificadores, commits y ADRs en inglés.

## Entrega de cambios: commit, push y tag

Al cerrar cada cambio pedido, el agente **entrega los comandos** de commit, push y tag
que corresponden a lo realizado — **no los ejecuta**. El usuario corre lo irreversible.
No es una preferencia: `git push` está en `deny` global en `opencode.jsonc`, así que la
entrega es necesariamente de comandos, nunca de ejecución.

| Situación | Qué entregar |
|---|---|
| Hay cambios en el working tree | `git add <paths>` + `git commit -m "<mensaje>"` |
| El cambio se publica en una rama | + `git push origin <rama>` |
| El cambio es una release (`VERSION` + `CHANGELOG.md` actualizados) | + `git tag v<VERSION>` + `git push origin v<VERSION>` |

Reglas de la entrega:

- Un bloque de comandos listo para copiar, con el `cd` al repo cuando haga falta y el
  resultado esperado de cada paso.
- El mensaje de commit sigue Conventional Commits:
  `feat|fix|test|refactor|chore|docs|ci|db(scope): mensaje`.
- `git add` con **paths explícitos** del cambio, nunca `.` ni `-A`: el working tree
  puede tener cambios ajenos que no forman parte de este cambio.
- El tag se propone solo cuando `VERSION` cambió; su nombre es el de `VERSION` con
  prefijo `v` (`v0.2.1`).
- Si el cambio todavía no está listo para publicarse, entrega solo el commit y
  explica qué falta.
- Si el cambio no toca archivos (por ejemplo, solo una explicación), dilo: no hay
  comandos que entregar.
- Antes de proponer los paths, corre `git status --short` y `git diff --stat` (están
  permitidos) para listar exactamente lo que cambió.

## Memoria entre sesiones, minimalismo y tokens (nativo, sin plugins)

| Necesidad | Mecanismo | Dónde |
|---|---|---|
| Contexto entre sesiones | Recuperar `STATE.md` al inicio + actualizarlo al cerrar fase (skill `context-persistence`) | `docs/context/` |
| Menor código posible | Skill `code-simplification` (filosofía vendorizada de `ponytail`): el diff más corto que funcione | Todos los agentes que escriben código |
| Ahorro de tokens | `tool_output` (trunca outputs de más de 1000 líneas / 32 KB y guarda el resto en disco) + `compaction` automática (conserva ~25k tokens recientes) | `opencode.jsonc` |
| Modelo por rol (opcional) | Bloque `agents` de `opencode.jsonc`, comentado por defecto: sin él, todos los roles usan el modelo de la sesión (`/models`) | `docs/guides/models-per-role.md` |

Cambiar este mecanismo (o agregar plugins externos de memoria/contexto) requiere ADR + aprobación del usuario. Los modelos por rol no son un default del kit: el usuario los habilita y edita cuando quiere.

## Estructura del repositorio

```text
docs/
  context/   # estado vivo entre sesiones (STATE.md, decisions-log.md)
  product/   # PRDs, problem statements, backlog priorizado
  specs/     # requisitos, historias de usuario, tickets (+ tickets/ por archivo)
  adr/       # Architecture Decision Records
  design/    # flujos UX, criterios visuales, auditorías de UI
  plans/     # planes de implementación del tech-lead
src/         # código (server/, features/, stores/, lib/...)
tests/       # pruebas unitarias e integración
e2e/         # pruebas Playwright
.opencode/   # agentes, skills y esta configuración
```

## Calidad y gates mínimos

- `npm run lint && npm run typecheck && npm run test` en verde antes de pedir revisión.
- Cambios de auth, sesiones, input no confiable o dependencias nuevas → revisión de `security-engineer` obligatoria.
- Toda dependencia nueva se justifica en la descripción del cambio (el reviewer audita contra `stack-guard`).
- Conventional Commits: `feat|fix|test|refactor|chore|docs|ci|db(scope): mensaje`.

## Skills clave del proyecto

Skills completas por rol en `.opencode/skills/`. Las más transversales:

- `stack-guard` — qué tecnologías son válidas (todos los agentes).
- `context7-query` — cómo consultar docs vigentes vía Context7 MCP.
- `writing-plans`, `verification-before-completion` — proceso del tech-lead.
- `context-persistence` — memoria entre sesiones sin plugins (ver sección siguiente).
- `code-simplification` — minimalismo estilo "lazy senior dev" (ver sección siguiente).
- `code-review` (proceso 2 ejes), `tdd`, `hono`, `drizzle-orm-patterns`, `better-auth-hono`, `react-best-practices`, `tanstack-query-zustand`, `postgres-best-practices`, `shadcn`, `playwright-best-practices`.

La proveniencia de las skills vendorizadas está en el frontmatter/header de cada `SKILL.md`; los cambios de stack o de skills requieren ADR.
