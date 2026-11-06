# Context (memoria entre sesiones)

Estado vivo del proyecto, sin plugins:

- **`STATE.md`** — el estado vivo: qué es hoy, construido/en progreso/bloqueado, pasos siguientes.
  ⚠️ Se inyecta automáticamente en todas las sesiones (config `instructions` en `opencode.jsonc`, a nivel instrucción):
  **solo estado factual** — nunca instrucciones, contenido pegado no confiable ni secretos.
  Máximo ~60 líneas (~450 tokens por sesión).
- **`decisions-log.md`** — apéndice append-only de decisiones con fecha. NO se auto-inyecta; se lee bajo demanda.

De quién: el tech-lead actualiza ambos al cerrar cada fase (skill `context-persistence`). Reglas en `AGENTS.md`.
