# Instalar el equipo en otro proyecto

El kit se **inyecta** en un proyecto existente: copia a la raíz los archivos del equipo y
siembra un `docs/context/` **vacío**. La memoria del kit (`STATE.md`, `decisions-log.md`
del repo) nunca viaja a tu proyecto.

Hay dos caminos que instalan exactamente lo mismo: **curl** (recomendado, un solo comando)
y **git clone** (alternativa para air-gapped o cuando prefieres revisar el árbol completo).

## Requisitos

- `sh` y coreutils (`cp`, `sed`, `cmp`).
- Modo curl: `curl` y `tar`.
- Modo clon: `git`.
- Un directorio de proyecto (existente o por crear).

## 1. Instalar con curl (recomendado)

```bash
cd ~/Proyectos/mi-proyecto        # párate en TU proyecto

# previsualizar: imprime el plan y no escribe nada
curl -fsSL https://raw.githubusercontent.com/naxrowdev/opencode-dev-team/main/kit/install.sh | sh -s -- --dry-run

# instalar (o actualizar) a la última versión estable
curl -fsSL https://raw.githubusercontent.com/naxrowdev/opencode-dev-team/main/kit/install.sh | sh
```

El script detecta que corre sin el árbol del kit, descarga el tarball de la última
**GitHub Release**, ejecuta el instalador desde un directorio temporal y lo limpia al
terminar. Nada queda copiado en tu proyecto salvo lo que corresponde.

Si el repo todavía no tiene releases, el comando corta con un mensaje que pide `--ref`;
no cae a `main` por su cuenta.

### Fijar una versión

```bash
# tag publicado
curl -fsSL https://raw.githubusercontent.com/naxrowdev/opencode-dev-team/main/kit/install.sh | sh -s -- --ref v0.3.0

# código no publicado (último commit de main)
curl -fsSL https://raw.githubusercontent.com/naxrowdev/opencode-dev-team/main/kit/install.sh | sh -s -- --ref main
```

Los flags van después de `-s --` porque `sh` los recibe como argumentos del script.

### Revisar antes de ejecutar

```bash
curl -fsSL -o /tmp/opencode-install.sh https://raw.githubusercontent.com/naxrowdev/opencode-dev-team/main/kit/install.sh
less /tmp/opencode-install.sh
sh /tmp/opencode-install.sh --ref v0.3.0
```

Ejecutado como archivo, el script hace lo mismo: sin árbol del kit al lado, descarga el
tarball y se re-ejecuta desde ahí.

### Verificar el tarball

```bash
# una vez, para fijar el artefacto
curl -fsSL -o kit.tar.gz https://codeload.github.com/naxrowdev/opencode-dev-team/tar.gz/v0.3.0
sha256sum kit.tar.gz        # en macOS: shasum -a 256 kit.tar.gz

# en otra máquina, con ese hash
curl -fsSL .../main/kit/install.sh | sh -s -- --ref v0.3.0 --sha256 <hash>
```

El checksum cubre el **tarball**, no el script; para el script está la variante de revisión
manual de arriba.

### Sin red (tarball local)

```bash
sh /tmp/opencode-install.sh --tarball ./kit.tar.gz
# o, con pipe:
cat /tmp/opencode-install.sh | sh -s -- --tarball ./kit.tar.gz
```

## 2. Instalar con git clone (alternativa)

```bash
cd ~/Proyectos/mi-proyecto                                # párate en TU proyecto
git clone git@github.com:naxrowdev/opencode-dev-team.git  # crea ./opencode-dev-team

sh opencode-dev-team/kit/install.sh --dry-run   # previsualizar
sh opencode-dev-team/kit/install.sh             # instalar en esta carpeta
rm -rf opencode-dev-team                        # el clon ya no hace falta
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
| `no se pudo resolver la última versión estable` | el repo no tiene releases publicadas (o no existe) | crea una Release para el tag, o pasa `--ref <tag\|rama>` (ej.: `--ref main`) |
| `no se pudo descargar ...` | red, proxy o URL inválida | revisa la conexión o usa `--tarball` con un artefacto local |
| `checksum no coincide` | el tarball no es el esperado | verifica el `--sha256` contra el artefacto correcto |
| `el tarball no contiene kit/install.sh` | apuntaste a un archivo equivocado | usa el tarball del repo (`codeload.github.com/<repo>/tar.gz/<ref>`) |
| `hace falta 'curl'` / `hace falta 'tar'` | modo curl sin dependencias | instala `curl` y `tar`, o usa el modo clon |
| `esa opción solo aplica al modo curl` | pasaste `--ref`/`--sha256`/`--tarball` a un instalador local | usa esos flags solo con `curl ... \| sh -s --` |
| `parece un placeholder de la documentación` | pegaste el ejemplo con `/ruta/a/mi-proyecto` en lugar de tu ruta real | usa la ruta real (ej.: `$HOME/Proyectos/mi-proyecto`) |
| `el destino está dentro del repo del kit` | ejecutaste el instalador desde la carpeta del kit | `cd ~/Proyectos/mi-proyecto` y vuelve a correr el comando |
| `el destino es el propio clon del kit` | quedaste parado dentro del clon (`opencode-dev-team/`) | vuelve a la raíz de tu proyecto (`cd ..`) |
| `no se pudo crear el destino ...` | falló `mkdir -p`: ruta no creable (padre sin permiso, o el padre es un archivo) | usa una ruta bajo un directorio donde tengas permisos |
| `ya existe .opencode/ y no lo instaló este kit` | hay config previa de otra fuente | revisa qué hay en `.opencode/` y usa `--force` si corresponde |

Si el destino aún no es un repo git, inicialízalo antes del `git add` sugerido: `git init`.

## 3. Verificar

```bash
cd ~/Proyectos/mi-proyecto
grep -n '"instructions"' opencode.jsonc   # referencias que deben existir en el repo
opencode mcp list                          # context7 conectado
opencode                                   # arranca con tech-lead
```

## Qué instala y qué no

| Grupo | Rutas | Política |
|---|---|---|
| Kit-owned | `.opencode/agents/`, `.opencode/skills/`, `docs/*/README.md`, guías instalables | copiar / actualizar en cada instalación |
| Raíz | `opencode.jsonc`, `AGENTS.md`, `.env.example`, `.gitignore` | create-if-absent; si ya existen, se dejan los tuyos y se agrega un `*.kit-new` para comparar |
| Directorios vacíos | `docs/specs/tickets/` | se crean (git no trackea carpetas vacías) |
| **Contexto** | `docs/context/STATE.md`, `docs/context/decisions-log.md` | **write-once**: se siembran vacíos solo si no existen; nunca se sobrescriben |
| Marcador | `.opencode/kit.json` | versión, fecha, `source` y `ref` de la instalación |
| **Nunca viaja** | `kit/`, `README.md`, `CHANGELOG.md`, `VERSION`, `docs/guides/setup-github.md`, y el `STATE.md`/`decisions-log.md` del kit | excluidos |

El instalador nunca ejecuta `git`; imprime el `git add` sugerido y el push lo haces tú.

## Conflicto: archivos `.kit-new`

Si tu proyecto ya tenía `AGENTS.md` y el kit instaló una versión más nueva, vas a encontrar
`AGENTS.md.kit-new`. Fusiona a mano lo que quieras y borra el `.kit-new`. Las reglas del
proyecto (tu stack, tu equipo) viven en tu `AGENTS.md`, no en el `.kit-new`.

## Actualizar

El comando de instalación es también el de actualización:

```bash
cd ~/Proyectos/mi-proyecto
curl -fsSL https://raw.githubusercontent.com/naxrowdev/opencode-dev-team/main/kit/install.sh | sh
```

Qué cambia y qué no:

- **Se refrescan**: `.opencode/agents/`, `.opencode/skills/` y los READMEs/guías que el kit
  distribuye. Cualquier edición local en esas rutas se pierde: si necesitas cambiarlas,
  hazlo en el kit o guárdalas en otro sitio.
- **Se conservan**: `opencode.jsonc`, `AGENTS.md`, `.env.example`, `.gitignore`. Si la
  versión nueva trae cambios en esos archivos, aparecen como `*.kit-new` para fusionar.
- **Intacto**: `docs/context/` (memoria del proyecto, write-once).
- **No se poda**: los archivos que el kit eliminó de una versión a otra siguen en tu
  proyecto; bórralos a mano si corresponden.
- **Marcador**: `.opencode/kit.json` se reescribe con la versión, fecha, `source` y `ref`
  nuevos.

Antes de actualizar, deja el working tree limpio (`git status`): no hay backup, y el
`git diff` posterior es la forma de revisar lo que se refrescó.

Si instalaste `.opencode/` a mano antes de 0.2.0, vuelve a instalar una vez con `--force` y
después el guard funciona solo.

## Desinstalar

El instalador deja un **manifiesto** en `.opencode/kit.json` (`"files"`) con la ruta de
cada archivo que escribió. El desinstalador borra exactamente esa lista: no adivina, no
hace `rm -rf` y no toca lo que agregaste tú.

```bash
cd ~/Proyectos/mi-proyecto

# plan: imprime qué borraría y no toca nada (comportamiento por defecto)
curl -fsSL https://raw.githubusercontent.com/naxrowdev/opencode-dev-team/main/kit/uninstall.sh | sh

# ejecutar
curl -fsSL https://raw.githubusercontent.com/naxrowdev/opencode-dev-team/main/kit/uninstall.sh | sh -s -- --yes
```

| Flag | Efecto |
|---|---|
| (sin flags) | **plan only**: lista lo que borraría y sale con 0 |
| `--yes` | ejecuta el plan |
| `--dry-run` | alias explícito del plan; combinado con `--yes` corta por contradictorio |
| `--purge-context` | además borra `docs/context/STATE.md` y `decisions-log.md` (memoria del proyecto) |
| `--remove-root-config` | además borra `opencode.jsonc`, `AGENTS.md`, `.env.example`, `.gitignore` |

Qué borra y qué conserva:

- **Borra**: los archivos del manifiesto (`.opencode/agents/`, `.opencode/skills/`, los
  `docs/*/README.md` y guías que instaló) y, al final, `.opencode/kit.json`. Después
  intenta `rmdir` en los directorios que quedaron vacíos: si una carpeta todavía tiene
  algo tuyo, sobrevive.
- **Conserva**: cualquier archivo que no esté en el manifiesto — tus agentes, tus skills,
  tus documentos. También `docs/context/` (memoria del proyecto) y la config raíz, salvo
  que pases el flag correspondiente.
- **Saltea** rutas inválidas del manifiesto (absolutas o con `..`) con un warning en el
  resumen: nunca puede escribir fuera del proyecto.
- No ejecuta `git`: imprime el `git status --short` y `git diff --stat` para que revises
  el resultado antes de commitear.

### Instalaciones sin manifiesto (anteriores a 1.0.0)

Si el `.opencode/kit.json` no tiene `"files"`, el desinstalador **se niega** en vez de
adivinar:

```bash
# 1) reinstalar con la versión actual: es idempotente y genera el manifiesto
curl -fsSL https://raw.githubusercontent.com/naxrowdev/opencode-dev-team/main/kit/install.sh | sh
# 2) ahora sí
curl -fsSL https://raw.githubusercontent.com/naxrowdev/opencode-dev-team/main/kit/uninstall.sh | sh -s -- --yes
```

### Límite conocido

Los archivos que una versión anterior del kit publicó y la actual ya no trae **no están
en el manifiesto**: el instalador no poda, así que el desinstalador tampoco los conoce.
Aparecen en el `git status` y se borran a mano.

## Uso en CI (opcional)

El selftest corre en cualquier máquina con `sh` y coreutils:

```bash
sh kit/selftest.sh
```

Verifica: la instalación fresh no arrastra estado del kit, el contexto es write-once, la
config preexistente se preserva, los guards rechazan destinos inválidos y el modo curl
funciona de punta a punta con un tarball local (`file://`).

En un pipeline, el modo curl evita clonar:

```bash
curl -fsSL https://raw.githubusercontent.com/naxrowdev/opencode-dev-team/main/kit/install.sh | sh -s -- --ref "$KIT_VERSION"
```
