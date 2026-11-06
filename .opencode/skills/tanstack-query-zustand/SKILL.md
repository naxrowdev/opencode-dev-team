---
name: tanstack-query-zustand
description: Patterns for TanStack Query + Axios (server state) and Zustand (UI state) in this React SPA. Use when writing data fetching, mutations, cache invalidation, pagination, or global state; when deciding where a piece of state belongs; or when touching files that import from '@tanstack/react-query', 'axios', or 'zustand'.
---

# TanStack Query + Zustand

No trustworthy community skill exists for this combination, so this is the project-standard. Read this before writing any data layer code. For exact option signatures of the installed versions (they change across majors), use `context7-query` instead of guessing.

## Division of responsibilities

| State belongs to... | Tool | Examples |
|---|---|---|
| The server | TanStack Query | users list, current session, product detail |
| Form state | React Hook Form | any `<form>` |
| The component | `useState` | open/closed dropdown, focused tab |
| App-wide UI/session | Zustand | theme, sidebar collapsed, cart draft, "returning to" page |
| **Never** Zustand | — | data fetched from the API (Query owns it) |

Rule of thumb: if it becomes stale when the server changes, it's Query's job. If two distant components need to share purely client-side state, Zustand. Otherwise local `useState`.

## Axios client

One configured client, no ad-hoc instances:

```ts
// src/lib/api-client.ts
import axios from "axios";

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL, // e.g. http://localhost:3000
  withCredentials: true, // Better Auth session cookie
});

api.interceptors.response.use(
  (r) => r,
  (err) => {
    // normalize API error shape once, here
    if (err.response?.data?.message) err.message = err.response.data.message;
    return Promise.reject(err);
  },
);
```

- Typed wrappers per resource (`src/features/<domain>/api.ts`), never `api` calls inside components.
- Export functions returning promises; components and hooks consume them.

## TanStack Query conventions

```ts
// src/features/products/hooks.ts
export const productKeys = {
  all: ["products"] as const,
  list: (filters?: Partial<Filters>) => [...productKeys.all, "list", filters ?? {}] as const,
  detail: (id: string) => [...productKeys.all, "detail", id] as const,
};
```

1. **Factories for query keys** per feature (above). Never inline key arrays.
2. **Queries in custom hooks** (`useProducts(filters)`), one hook per use case; components never call `useQuery` directly with ad-hoc keys.
3. `staleTime` > 0 for read-heavy data (default 30s); `gcTime` default; mark auth/session queries `staleTime: Infinity` only if the server can't change it mid-session.
4. **Errors:** rely on the normalized Axios error; use `error instanceof AxiosError` guards in UI. Set a global error boundary handler in `QueryClient`.
5. **Mutations** also in hooks, with `onSuccess` invalidating precisely:

```ts
useMutation({
  mutationFn: (input: ProductInput) => createProduct(input),
  onSuccess: () => {
    qc.invalidateQueries({ queryKey: productKeys.all });
  },
});
```

6. **Optimistic updates** only for clear single-entity edits; cancel in-flight refetches, rollback `onError`, always invalidate `onSettled`.
7. **Pagination:** `placeholderData: keepPreviousData`; infinite scroll via `useInfiniteQuery` with page param.
8. One `QueryClient` created once in `src/main.tsx` (module scope or `useState(() => new QueryClient(...))`); never `new QueryClient()` per component or render.
9. `isPending` vs `isFetching`: design on `isPending`, show background refresh with `isFetching` only when visible.

## Zustand conventions

Files per store in `src/stores/` (or feature folder for feature-scoped stores):

```ts
// src/stores/ui-store.ts
import { create } from "zustand";

interface UiState {
  sidebarOpen: boolean;
  toggleSidebar: () => void;
}

export const useUiStore = create<UiState>()((set) => ({
  sidebarOpen: true,
  toggleSidebar: () => set((s) => ({ sidebarOpen: !s.sidebarOpen })),
}));
```

1. `create<T>()(...)` curried form for exact TS types. No `immer` or `devtools` middleware unless needed — add `persist` (localStorage) only for genuinely persistent prefs like theme.
2. **Selectors everywhere:** `const open = useUiStore((s) => s.sidebarOpen)` — never destructure the whole store (kills re-render granularity). Compose with `useShallow` only when you need multiple fields.
3. Actions live in the store (as in `toggleSidebar`); components don't `setState` on store internals.
4. No async data loading inside stores. If a store needs server data, take it from Query's cache on the server's terms (subscribe in a hook), not the other way around.
5. Keep stores small and single-purpose; multiple stores > one god store.

## Testing

- Query hooks: use `renderHook` with a fresh `QueryClient` and `QueryClientProvider` (Testing Library). Never share the real app client in tests.
- Mock Axios with `vi.spyOn(api, 'get')` / `vi.mock` over the feature api module (this repo does not use MSW; keep the dependency set minimal).
- Zustand stores are plain modules — test actions by calling them and asserting state; reset store between tests if needed.

## Review checklist

- [ ] No `new QueryClient()` or `axios.create()` outside the setup modules.
- [ ] No raw `fetch` / `useEffect` data loading anywhere.
- [ ] Query keys created via key factories.
- [ ] Store accesses use narrow selectors.
- [ ] Nothing server-owned lives in Zustand.
