---
name: stack-guard
description: Enforces the fixed technology stack of this project. Use before writing any code, adding a dependency, or scaffolding a module — and always when tempted to choose a library, framework, or tool. Check this skill whenever a change might introduce a new dependency or drift from the approved stack.
---

# Stack Guard

The stack of this project is fixed. It exists to keep the codebase reviewable by humans and predictable for agents. Do not propose, install, or scaffold anything outside it without an ADR approved by the user (the tech-lead never approves stack changes alone).

## Approved stack (the only options)

| Layer | Approved | Notes |
|---|---|---|
| Language | TypeScript (strict) | Full-stack, ESM |
| Backend framework | **Hono.js** | Express allowed only if the user explicitly requests it |
| Database | **PostgreSQL** (Docker local) | Postgres 16+ |
| DB access | **Drizzle ORM + Drizzle Kit** | Schema-first, `drizzle-kit push/migrate` |
| Auth | **Better Auth** | With Drizzle adapter |
| Validation | **Zod** (v4) | Shared schemas API ⇄ forms |
| Frontend | **React 19** (SPA, Vite) | NOT Next.js, NOT Remix |
| Forms | **React Hook Form** | Resolver via Zod |
| Server state | **TanStack Query + Axios** | Not `fetch` wrappers in components |
| UI state | **Zustand** | UI/session state only |
| UI kit | **shadcn/ui + Tailwind CSS** | Radix primitives underneath |
| Testing | Vitest + Testing Library + Playwright | Unit/integration/E2E |
| Docs lookup | Context7 MCP | For current library APIs |

## Forbidden (auto-reject in review)

- Next.js, Remix, TanStack Start — frontend is a Vite SPA.
- NestJS, Fastify, Koa, tRPC, oRPC, Express (unless user-approved) — backend is Hono.
- Prisma, TypeORM, Mongoose, Kysely, Sequelize, Supabase SDK — data layer is Drizzle.
- Auth.js/NextAuth, Lucia, Clerk, Supabase Auth — auth is Better Auth.
- Redux (Toolkit), Jotai, Recoil, MobX, RTK Query, SWR — state is TanStack Query + Zustand.
- Material UI, Ant Design, Chakra, Mantine — UI is shadcn/ui + Tailwind.
- Axios alternatives (ky, ofetch) and raw `fetch` in components.
- Any CSS-in-JS (styled-components, Emotion) or utility kit other than Tailwind.
- Any DB other than PostgreSQL.

## Skill map (where the deep knowledge lives)

| Layer | Skills |
|---|---|
| Backend | `hono`, `drizzle-orm-patterns`, `better-auth-hono`, `postgres-best-practices`, `zod-validation-utilities` |
| Frontend | `react-best-practices`, `composition-patterns`, `shadcn`, `tailwind-design-system`, `react-hook-form`, `tanstack-query-zustand` |
| Cross | `context7-query`, `stack-guard` (this) |

No skill covers a layer you need? Use `context7-query` to fetch current official docs — never invent API signatures.

## Before installing a package

1. Is it on the approved list (directly or as transitive wiring)? → OK.
2. Does it duplicate approved functionality? → forbidden; extend the approved lib or write the small util locally.
3. Is it genuinely missing from the stack (e.g., a chart lib)? → propose it to the tech-lead with a one-paragraph justification; the tech-lead may approve **small, leaf-level additions** (UI widget libs, date utils, icons) without an ADR. Framework/data/CI-level changes always require an ADR.
4. Always pin exact versions; record new deps in the change description so the code-reviewer can audit.

## Drift response

If you find forbidden code already in the repo, flag it to the tech-lead with a migration note; do **not** silently rewrite it during unrelated tasks.
