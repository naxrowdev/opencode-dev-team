# Instalar el equipo en otro proyecto

El kit se **inyecta** en un proyecto existente; no se clona dentro de él. El
instalador copia solo los archivos del equipo y siembra un contexto **vacío**,
así el `STATE.md` y el `decisions-log.md` del repo del kit nunca viajan a tu
proyecto.

## Requisitos

- `sh` y coreutils (`cp`, `sed`, `cmp`). Sin dependencias.
- Un directorio de proyecto (existente o por crear).

## 1. Clonar el kit (fuera de tu proyecto)

```bash
git clone git@github.com:naxrowdev/opencode-dev-team.git /tmp/opencode-dev-team
cd /tmp/opencode-dev-team
```

## 2. Instalar en tu proyecto

```bash
# Previsualizar qué se va a copiar (no escribe nada)
sh kit/install.sh --dry-run /ruta/a/tu-proyecto

# Instalar
sh kit/install.sh /ruta/a/tu-proyecto
```

Si el destino ya tiene `.opencode/` de otra fuente, el instalador se niega;
podés forzarlo con `--force` (mira el diff antes).

## 3. Verificar

```bash
cd /ruta/a/tu-proyecto
grep -n '"instructions"' opencode.jsonc   # referencias que deben existir en el repo
opencode mcp list                          # context7 conectado
opencode                                   # arranca con tech-lead
```

## Qué instala y qué no

| Grupo | Rutas | Política |
|---|---|---|
| Kit-owned | `.opencode/agents/`, `.opencode/skills/`, `docs/*/README.md` | copiar / actualizar en cada re-instalación |
| Raíz | `opencode.jsonc`, `AGENTS.md`, `.env.example`, `.gitignore` | create-if-absent; si ya existen, se dejan los tuyos y se agrega un `*.kit-new` para comparar |
| Directorios vacíos | `docs/specs/tickets/` | se crean (git no trackea carpetas vacías) |
| **Contexto** | `docs/context/STATE.md`, `docs/context/decisions-log.md` | **write-once**: se siembran vacíos solo si no existen; nunca se sobrescriben |
| Marcador | `.opencode/kit.json` | versión y fecha de la instalación |
| **Nunca viaja** | `kit/`, `README.md`, `CHANGELOG.md`, `VERSION`, `docs/guides/setup-github.md`, y el `STATE.md`/`decisions-log.md` del kit | excluidos |

El instalador nunca ejecuta `git`; imprime el `git add` sugerido y el push lo
hacés vos.

## Conflicto: archivos `.kit-new`

Si tu proyecto ya tenía `AGENTS.md` y el kit instaló una versión más nueva,
vas a encontrar `AGENTS.md.kit-new`. Mergeá a mano lo que quieras y borrá el
`.kit-new`. Las reglas del proyecto (tu stack, tu equipo) viven en tu
`AGENTS.md`, no en el `.kit-new`.

## Re-instalar (actualizar)

Correr el instalador de nuevo sobre un proyecto ya instalado **solo
actualiza los archivos kit-owned** (agentes, skills, READMEs de `docs/`) y
escribe el `kit.json` nuevo. `docs/context/` queda exactamente como lo dejó tu
tech-lead: es memoria del proyecto.

El marcador `.opencode/kit.json` marca qué configuración pertenece al kit. Si
instalaste `.opencode/` a mano antes de 0.2.0, re-instalá una vez con `--force`
y después el guard funciona solo.

## Uso en CI (opcional)

El selftest corre en cualquier máquina con `sh` y coreutils:

```bash
sh kit/selftest.sh
```

Verifica: la instalación fresh no arrastra estado del kit, el contexto es
write-once, la config preexistente se preserva y los guards rechazan
destinos inválidos.
