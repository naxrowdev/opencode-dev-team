# Instalar el equipo en otro proyecto

El kit se **inyecta** en un proyecto existente: lo clonás como carpeta temporal *dentro*
de tu proyecto, y el instalador copia a la raíz solo los archivos del equipo y siembra un
`docs/context/` **vacío**. Todo se corre desde la raíz del proyecto, sin `cd` dentro del
clon; el clon queda descartable en cuanto el instalador termina, y la memoria del kit
(`STATE.md`, `decisions-log.md` del repo) nunca viaja a tu proyecto.

## Requisitos

- `sh` y coreutils (`cp`, `sed`, `cmp`). Sin dependencias.
- Un directorio de proyecto (existente o por crear).

## 1. Clonar el kit (desde tu proyecto)

```bash
cd ~/Proyectos/mi-proyecto                                # parate en TU proyecto
git clone git@github.com:naxrowdev/opencode-dev-team.git  # crea ./opencode-dev-team
```

## 2. Instalar en tu proyecto

```bash
# desde la raíz de TU proyecto, sin entrar al clon y sin argumentos
sh opencode-dev-team/kit/install.sh --dry-run   # previsualizar (no escribe nada)
sh opencode-dev-team/kit/install.sh             # instalar en esta carpeta
```

El resumen te va a mostrar `destino: ... (directorio actual)` — todo cae en la raíz del
proyecto. Al terminar, el instalador te avisa que el clon es descartable:

```bash
rm -rf opencode-dev-team         # el kit ya está inyectado; el clon no hace falta más
```

Variante (clonar a otro lado y pasar la ruta):

```bash
git clone git@github.com:naxrowdev/opencode-dev-team.git /tmp/opencode-dev-team
sh /tmp/opencode-dev-team/kit/install.sh ~/Proyectos/mi-proyecto
```

El destino puede no existir aún: el instalador crea el directorio con `mkdir -p`.

## Si el instalador corta

| Mensaje | Causa | Qué hacer |
|---|---|---|
| `parece un placeholder de la documentación` | pegaste el ejemplo con `/ruta/a/mi-proyecto` en lugar de tu ruta real | usá la ruta real (ej.: `$HOME/Proyectos/mi-proyecto`) |
| `el destino está dentro del repo del kit` | estás ejecutando el instalador desde la carpeta del kit (`cd` al proyecto primero) | `cd ~/Proyectos/mi-proyecto` y volvé a correr el comando |
| `el destino es el propio clon del kit` | quedaste parado dentro de la carpeta del clon (`opencode-dev-team/`) | volvé a la raíz de tu proyecto (`cd ..`) y correr el comando ahí, sin entrar al clon |
| `no se pudo crear el destino ...` | falló `mkdir -p`: la ruta no es creable (directorios padre sin permiso, o el padre es un archivo) | usá una ruta bajo un directorio donde tengas permisos |
| `ya existe .opencode/ y no lo instaló este kit` | hay config previa de otra fuente | revisá qué hay en `.opencode/` y usá `--force` si corresponde (mirá el diff antes) |

Si el destino aún no es un repo git, inicialo antes del `git add` sugerido: `git init`.

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
