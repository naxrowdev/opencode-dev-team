---
name: better-auth-hono
description: Integrates Better Auth with Hono, Drizzle ORM and PostgreSQL in this project. Use when setting up or extending authentication — server config, mounting the handler, session handling on the client, Drizzle auth schema, social login, 2FA/organization/other plugins, protected routes, or auth-related database migrations.
---

# Better Auth × Hono × Drizzle

This is the project-specific adaptation of Better Auth (the community skill targeted NestJS/Next.js — its reusable references are vendored in `references/`). Read this SKILL.md first, then the reference you need. Validate every signature against the installed version with `context7-query`; Better Auth moves fast.

## Server bootstrap

```ts
// src/server/auth.ts
import { betterAuth } from "better-auth";
import { drizzleAdapter } from "better-auth/adapters/drizzle";
import { db } from "./db";

export const auth = betterAuth({
  database: drizzleAdapter(db, { provider: "pg" }),
  emailAndPassword: { enabled: true },
  trustedOrigins: [import.meta.env?.VITE_APP_URL].filter(Boolean) as string[],
});
```

```ts
// src/server/index.ts — mounting on Hono
import { Hono } from "hono";
import { auth } from "./auth";
import { cors } from "hono/cors";

const app = new Hono();

app.use("*", cors({
  origin: process.env.FRONTEND_URL ?? "http://localhost:5173",
  credentials: true,
}));

// Better Auth handles its own routing; pass the raw Request.
app.on(["POST", "GET"], "/api/auth/*", (c) => auth.handler(c.req.raw));
```

- Never send custom JSON to `auth.handler` routes; give it `c.req.raw` untouched.
- `BETTER_AUTH_SECRET` and `BETTER_AUTH_URL` in the server `.env` (never commit it; `.env.example` documents them).
- CSRF/origin: keep `trustedOrigins` explicit — no wildcard origins in prod config.

## Client (React SPA)

```ts
// src/lib/auth-client.ts
import { createAuthClient } from "better-auth/react";

export const authClient = createAuthClient({
  baseURL: import.meta.env.VITE_API_URL,
});
```

- Wrap the app in `AuthQueryProvider`? No — in this auth-critical SPA keep the session in TanStack Query ("server state") and expose it via a small hook the `bootstrapSession` feature owns; component code reads it like any other query.
- Protect routes by rendering an auth gate against the session query, not by hiding UI only.

## Session middleware (Hono)

```ts
import { createAuthMiddleware } from "better-auth/api";
// or use the validated pattern:
app.use("/api/*", async (c, next) => {
  const session = await auth.api.getSession({ headers: c.req.raw.headers });
  if (!session) return c.text("Unauthorized", 401);
  c.set("session", session); // needs Hono Variables typing
  await next();
});
```

Referenced `session.user` types come from Better Auth's type export — import them, don't reinvent.

## Auth schema via Drizzle

- Generate core tables with the CLI: `npx @better-auth/cli generate` → writes to Drizzle schema. Review the generated file against `references/schema.md`.
- Custom user fields (e.g., `role`) go through `user.additionalFields` in `betterAuth({ user: { additionalFields: { role: { type: "string" } } } })`; the generated Drizzle schema must include them.
- After schema changes run Drizzle Kit migrations (`drizzle-kit generate` + `migrate`) — see `drizzle-orm-patterns`.

## Plugins

Plugin knowledge lives in `references/plugins.md` (organization, 2FA, passkey, magic link…). Rules:

1. Add one plugin at a time; server `plugins: [...]` + matching client re-exports (`authClient.<plugin>`).
2. Plugins that add tables require re-running the CLI generate + Drizzle migration.
3. Check `context7-query` for current option names before enabling a plugin from memory.

## References index

| File | When |
|---|---|
| `references/schema.md` | generated tables, custom fields |
| `references/plugins.md` | adding official plugins |
| `references/best-practices.md` | secrets, session hardening, cookies |
| `references/patterns.md` | common integration patterns |
| `references/examples.md` | copyable snippets |
| `references/social-providers.md` | OAuth providers (GitHub, Google…) |
| `references/mfa-2fa.md` | 2FA flows |

The `nextjs-setup.md` and `nestjs-setup.md` files were deliberately **not vendored** — they describe architectures this project doesn't use.

## Hard rules

- Auth endpoints (`/api/auth/*`) are never decorated with project middleware that could swallow responses.
- Never store or log secrets from `auth.handler` flow; never commit `.env`.
- Any change to auth = security-engineer review before merge (involve the `security-engineer` subagent).
