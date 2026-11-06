---
name: context7-query
description: How to query Context7 MCP for up-to-date library documentation. Use whenever you are about to call an API of Hono, Drizzle, Better Auth, Zod, TanStack Query, Axios, Zustand, React Hook Form, shadcn/ui, Tailwind, or Vitest from memory, and whenever a skill is missing, stale, or silent about the exact signature, option, or version you need.
---

# Context7 Query

Context7 (MCP server `context7`) serves live, version-specific documentation. This project forbids inventing library APIs. When in doubt, query — one call is cheaper than a broken build.

## When to use

- The skill files don't cover the exact function, option, hook, or config key you need.
- The skill was written for an older major version than the one in `package.json`.
- You are adding a new integration point (e.g., first OAuth provider, first transaction with Drizzle).
- You are tempted to write an import path or type signature from memory.

Do **not** query for project-local code, business logic, or things already documented in `AGENTS.md`, specs, or skills.

## How to call (Code Mode)

Context7 tools live under `tools.context7` inside `{ code }` of the `execute` tool:

1. `resolve-library-id` — map a library name to a Context7 library ID.
2. `query-docs` — fetch docs for that ID, scoped to a single topic per call.

```js
// 1. Resolver
const r = await tools.context7["resolve-library-id"]({
  query: "mounting Better Auth handler on Hono",
  libraryName: "Better Auth",
});
// pick the id like '/better-auth/better-auth' (add '/vX.Y.Z' if the repo pins a version)

// 2. Docs, scoped to ONE topic per call
const d = await tools.context7["query-docs"]({
  libraryId: "/better-auth/better-auth",
  query: "Hono integration: mounting auth.handler and session middleware",
  language: "TypeScript",
});
```

Separate concepts → separate `query-docs` calls (e.g., one for "drizzle-kit migrations", another for "useFieldArray"), never one broad query.

## Rules

1. **Narrow the topic** ("drizzle-kit migrations", "useFieldArray") — not "docs for drizzle".
2. Prefer querying the **versions in `package.json`**; if versions differ from docs examples, trust `package.json`.
3. Summarize what you learned in 2–3 lines in your final report (claim → source snippet) so the tech-lead can verify without re-querying.
4. Never paste large doc dumps into code comments or specs; link the concept.
5. If Context7 is down or returns nothing: say so explicitly and mark the uncertain APIs with `// VERIFY: from memory — confirm against docs` in the code.
6. Query one library per need; don't chain speculative fetches "just in case".

## Map: where skills end and Context7 begins

| Library | Has skill (read first) | Query Context7 for |
|---|---|---|
| Hono | `hono` | middleware details, streaming, adapters |
| Drizzle | `drizzle-orm-patterns` | release-specific APIs, new query builders |
| Better Auth | `better-auth-hono` | new plugin APIs, migration notes |
| Zod | `zod-validation-utilities` | v4-only APIs |
| TanStack Query / Zustand / Axios | `tanstack-query-zustand` | exact option signatures, devtools config |
| React Hook Form | `react-hook-form` | new APIs after 7.82 |
| shadcn/ui / Tailwind | `shadcn`, `tailwind-design-system` | component props, new registry options |
| Vitest | `tdd`, `test-master` | config options, newer matchers |
