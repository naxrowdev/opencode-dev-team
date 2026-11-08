#!/bin/sh
# install.sh — install the agentic dev team kit into a target project.
#
# Local mode (from a clone or worktree):
#   kit/install.sh [TARGET_DIR] [--dry-run] [--force]
#
# Curl mode (no clone: this file fetches a kit release tarball and runs it):
#   curl -fsSL https://raw.githubusercontent.com/naxrowdev/opencode-dev-team/main/kit/install.sh | sh
#   curl -fsSL <misma-url> | sh -s -- --ref v1.0.0 --dry-run
#
# Copies the kit-owned files (.opencode/agents, .opencode/skills, docs READMEs),
# seeds an EMPTY project context from kit/templates/, and never carries over the
# kit repository's own state (its STATE.md, decisions-log.md, README, CHANGELOG).
#
# Safe to re-run: kit-owned files are refreshed, docs/context/* is write-once.
# This script NEVER runs git. See docs/guides/installing-into-a-project.md.
#
# POSIX sh, no dependencies beyond the coreutils (curl + tar in curl mode).

set -eu

usage() {
  cat <<'EOF'
Usage: kit/install.sh [TARGET_DIR] [options]                         (local)
       curl -fsSL <url>/kit/install.sh | sh [-s -- options]          (curl)

  TARGET_DIR      Project to install into. Omit it to install into the folder
                  you are in (recommended: cd into your project first).
  --dry-run       Print the plan, write nothing.
  --force         Overwrite a .opencode/ that was not installed by this kit.
  -h, --help      Show this help.

Curl mode only (the script downloads a kit tarball and runs it):
  --ref <tag|rama>  Version to install. Default: the latest GitHub release.
  --sha256 <hex>    Verify the downloaded tarball (sha256sum or shasum -a 256).
  --tarball <path>  Install from a local tarball instead of the network.
  --repo <owner/repo>  Source repository (default: naxrowdev/opencode-dev-team).

Copies kit-owned files, seeds an empty docs/context/, and refreshes
.opencode/kit.json. Never touches docs/context/ if it already exists.
EOF
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

# ── Curl mode: fetch the kit tarball and run the extracted copy ───────────────
# When this file is piped to `sh`, $0 is the shell and the kit tree is not on
# disk. This block downloads a released tarball into a temp dir, runs that copy
# with the same arguments, and cleans up. The extracted copy always sees its
# assets, so the bootstrap cannot recurse.
ODT_REPO_DEFAULT="naxrowdev/opencode-dev-team"
ODT_DIR=$(CDPATH= cd -- "$(dirname -- "${0:-sh}")/.." 2>/dev/null && pwd || true)
if [ ! -d "$ODT_DIR/.opencode/agents" ] || [ ! -f "$ODT_DIR/kit/include.txt" ]; then
  ODT_REPO=${ODT_REPO:-$ODT_REPO_DEFAULT}
  ODT_REF=""
  ODT_SHA=""
  ODT_TARBALL=""
  ODT_DRY=0
  ODT_FORCE=0
  ODT_HELP=0
  ODT_TARGET=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --ref)       [ $# -ge 2 ] || die "falta el valor de --ref"; ODT_REF=$2; shift 2 ;;
      --ref=*)     ODT_REF=${1#*=}; shift ;;
      --sha256)    [ $# -ge 2 ] || die "falta el valor de --sha256"; ODT_SHA=$2; shift 2 ;;
      --sha256=*)  ODT_SHA=${1#*=}; shift ;;
      --tarball)   [ $# -ge 2 ] || die "falta el valor de --tarball"; ODT_TARBALL=$2; shift 2 ;;
      --tarball=*) ODT_TARBALL=${1#*=}; shift ;;
      --repo)      [ $# -ge 2 ] || die "falta el valor de --repo"; ODT_REPO=$2; shift 2 ;;
      --repo=*)    ODT_REPO=${1#*=}; shift ;;
      --dry-run)   ODT_DRY=1; shift ;;
      --force)     ODT_FORCE=1; shift ;;
      -h|--help)   ODT_HELP=1; shift ;;
      -*)          die "opción desconocida en modo curl: $1 (ver --help)" ;;
      *)
        [ -z "$ODT_TARGET" ] || die "solo se acepta un TARGET_DIR"
        ODT_TARGET=$1
        shift
        ;;
    esac
  done

  if [ "$ODT_HELP" -eq 1 ]; then usage; exit 0; fi

  odt_fetch() {
    case "$1" in
      http://*|https://*|file://*) ;;
      *) die "URL de tarball no soportada: $1" ;;
    esac
    curl -fsSL "$1" -o "$2" || die "no se pudo descargar $1"
  }

  odt_verify() {
    odt_want=$(printf '%s' "$2" | tr 'A-F' 'a-f')
    if command -v sha256sum >/dev/null 2>&1; then
      odt_got=$(sha256sum "$1" | cut -d' ' -f1)
    elif command -v shasum >/dev/null 2>&1; then
      odt_got=$(shasum -a 256 "$1" | cut -d' ' -f1)
    else
      die "no hay sha256sum ni shasum para verificar --sha256"
    fi
    [ "$odt_got" = "$odt_want" ] || die "checksum no coincide: esperado $odt_want, obtenido $odt_got"
  }

  odt_latest_ref() {
    # GitHub redirects /releases/latest to the tag page: no API call, no rate limit.
    odt_url=$(curl -fsS -o /dev/null -w '%{redirect_url}' "https://github.com/$1/releases/latest" 2>/dev/null || true)
    case "$odt_url" in
      */releases/tag/*) printf '%s' "${odt_url##*/releases/tag/}" ;;
      *) return 1 ;;
    esac
  }

  command -v curl >/dev/null 2>&1 || die "hace falta 'curl' para el modo curl"
  command -v tar  >/dev/null 2>&1 || die "hace falta 'tar' para el modo curl"

  ODT_TMP=$(mktemp -d "${TMPDIR:-/tmp}/opencode-dev-team.XXXXXX") || die "no se pudo crear un directorio temporal"
  trap 'rm -rf "$ODT_TMP"' 0

  ODT_ARCHIVE="$ODT_TMP/kit.tar.gz"
  if [ -n "$ODT_TARBALL" ]; then
    [ -f "$ODT_TARBALL" ] || die "no existe el tarball: $ODT_TARBALL"
    cp "$ODT_TARBALL" "$ODT_ARCHIVE"
    ODT_REF=${ODT_REF:-local}
  else
    if [ -n "${ODT_TARBALL_URL:-}" ]; then
      odt_url=$ODT_TARBALL_URL
      ODT_REF=${ODT_REF:-url-override}
    else
      if [ -z "$ODT_REF" ]; then
        ODT_REF=$(odt_latest_ref "$ODT_REPO") || die "no se pudo resolver la última versión estable de $ODT_REPO (¿repo publicado y con releases?); usa --ref <tag|rama> (ej.: --ref main)"
      fi
      odt_url="https://codeload.github.com/$ODT_REPO/tar.gz/$ODT_REF"
    fi
    printf 'descargando %s\n' "$odt_url"
    odt_fetch "$odt_url" "$ODT_ARCHIVE"
  fi

  if [ -n "$ODT_SHA" ]; then odt_verify "$ODT_ARCHIVE" "$ODT_SHA"; fi

  mkdir -p "$ODT_TMP/src"
  tar xzf "$ODT_ARCHIVE" -C "$ODT_TMP/src" || die "no se pudo extraer el tarball del kit"
  ODT_CHILD=$(ls -d "$ODT_TMP"/src/*/kit/install.sh 2>/dev/null | head -n 1 || true)
  [ -n "$ODT_CHILD" ] || die "el tarball no contiene kit/install.sh — ¿es el archivo correcto?"

  set --
  if [ "$ODT_DRY" -eq 1 ]; then set -- "$@" --dry-run; fi
  if [ "$ODT_FORCE" -eq 1 ]; then set -- "$@" --force; fi
  if [ -n "$ODT_TARGET" ]; then set -- "$@" "$ODT_TARGET"; fi

  KIT_SOURCE_URL="https://github.com/$ODT_REPO" KIT_REF="$ODT_REF" sh "$ODT_CHILD" "$@"
  exit $?
fi

# ── Locations ─────────────────────────────────────────────────────────────────
KIT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
KIT_DIR="$KIT_ROOT/kit"
TODAY=$(date +%F)
KIT_VERSION=$(tr -d '[:space:]' < "$KIT_ROOT/VERSION" 2>/dev/null || echo "unknown")

# ── Defaults ──────────────────────────────────────────────────────────────────
TARGET="."
TARGET_GIVEN=0
DRY_RUN=0
FORCE=0

log() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[dry-run] %s\n' "$*"
  else
    printf '%s\n' "$*"
  fi
}

# ── Args ──────────────────────────────────────────────────────────────────────
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --force)   FORCE=1 ;;
    -h|--help) usage; exit 0 ;;
    --ref|--ref=*|--sha256|--sha256=*|--tarball|--tarball=*|--repo|--repo=*)
      die "esa opción solo aplica al modo curl (curl -fsSL <url>/kit/install.sh | sh -s -- ...); en modo local no hace falta"
      ;;
    -*)        die "opción desconocida: $1 (ver --help)" ;;
    *)
      case "$TARGET_GIVEN" in
        0) TARGET=$1; TARGET_GIVEN=1 ;;
        *)   die "solo se acepta un TARGET_DIR" ;;
      esac
      ;;
  esac
  shift
done

# ── Sanity of the kit itself ──────────────────────────────────────────────────
[ -d "$KIT_ROOT/.opencode/agents" ] || die "no encuentro .opencode/agents en $KIT_ROOT — ¿estás corriendo el install.sh del kit?"
[ -f "$KIT_DIR/include.txt" ] || die "falta $KIT_DIR/include.txt"

read_list() {
  sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$1"
}

# ── Guard the target ──────────────────────────────────────────────────────────
# The guide's example blocks are copy-paste magnets: catch placeholder paths
# verbatim, before anything is created on disk.
case "$TARGET" in
  /ruta|*/ruta/*|/path/to/*|/your/*)
    die "el destino '$TARGET' parece un placeholder de la documentación — reemplázalo por la ruta real de tu proyecto (ej.: $HOME/Proyectos/mi-proyecto)"
    ;;
esac

# ── Resolve the target ────────────────────────────────────────────────────────
if [ "$DRY_RUN" -eq 0 ]; then
  mkdir -p "$TARGET" 2>/dev/null || die "no se pudo crear el destino '$TARGET' (¿ruta válida? ¿permisos del directorio padre?)"
fi

if [ -d "$TARGET" ]; then
  TARGET=$(CDPATH= cd -- "$TARGET" && pwd)
elif [ "$DRY_RUN" -eq 1 ]; then
  case "$TARGET" in
    /*) : ;;
    *)  TARGET="$PWD/$TARGET" ;;
  esac
  log "aviso: el destino '$TARGET' no existe todavía; se creará al instalar"
else
  die "no se pudo asegurar el destino: $TARGET"
fi

# The primary flow keeps a clone of the kit inside the project — but only as a
# vehicle: installing INTO the kit itself (repo or clone) would turn kit state
# into the project's own state
if [ -f "$TARGET/kit/install.sh" ]; then
  die "el destino es el propio clon del kit (tiene kit/install.sh) — ejecuta el instalador desde la raíz de tu proyecto, sin entrar al clon"
fi
case "$TARGET/" in
  "$KIT_ROOT/"*) die "el destino está dentro del repo del kit ($KIT_ROOT) — elige otro directorio" ;;
esac
case "$TARGET" in
  */.git|*/.git/*) die "el destino apunta a un directorio .git" ;;
esac

if [ "$DRY_RUN" -eq 0 ] && [ -d "$TARGET/.opencode" ] && [ ! -f "$TARGET/.opencode/kit.json" ] && [ "$FORCE" -eq 0 ]; then
  die "ya existe .opencode/ y no lo instaló este kit; usa --force para sobrescribirlo"
fi

# ── Validation: nothing excluded may be included ──────────────────────────────
for entry in $(read_list "$KIT_DIR/include.txt"); do
  for ex in $(read_list "$KIT_DIR/exclude.txt"); do
    case "$entry" in
      "$ex"|"$ex"/*)
        die "include.txt incluye '$entry', que exclude.txt prohíbe ('$ex')"
        ;;
    esac
  done
done

# ── Install ───────────────────────────────────────────────────────────────────
printf 'instalando opencode-dev-team %s\n' "$KIT_VERSION"
printf '  kit:    %s\n' "$KIT_ROOT"
if [ "$TARGET_GIVEN" -eq 0 ]; then
  printf '  destino: %s (directorio actual)\n\n' "$TARGET"
else
  printf '  destino: %s\n\n' "$TARGET"
fi

C_COPY=0
C_SEED=0
C_SKIP=0
C_CONFLICT=0

# Manifest of kit-owned files: the uninstaller never guesses, it deletes exactly
# this list. It is built from the SOURCE tree, so files the project added to
# .opencode/ are not in it. Root config and docs/context are project-owned and
# stay out (they are create-if-absent / write-once, not kit-owned).
KIT_FILES=""
manifest_add() {
  KIT_FILES="${KIT_FILES}${1}
"
}

# Find must not run in a pipeline: the while body has to stay in this shell for
# KIT_FILES to accumulate.
manifest_add_tree() {
  _tree=$1
  _list=$(find "$_tree" -type f -print 2>/dev/null || true)
  while IFS= read -r _f; do
    [ -n "$_f" ] || continue
    manifest_add "${_f#"$KIT_ROOT"/}"
  done <<EOF
$_list
EOF
}

copy_entry() {
  rel=$1
  case "$rel" in
    ""|"."|"./"|"/"|".."|"../") return 0 ;; # a blank entry must never mean "the whole kit"
  esac
  if [ "${rel%/}" != "$rel" ]; then
    # trailing slash: empty directory marker (git cannot track these)
    log "mkdir   ${rel%/}"
    [ "$DRY_RUN" -eq 1 ] || mkdir -p "$TARGET/${rel%/}"
    C_COPY=$((C_COPY + 1))
    return
  fi
  for src in "$KIT_ROOT/$rel"; do
    [ -e "$src" ] || { log "warn    $rel (no existe en el kit; salteado)"; continue; }
    rel_real=${src#"$KIT_ROOT"/}
    if [ -z "$rel_real" ] || [ "$rel_real" = "." ]; then
      log "warn    entrada inválida en include.txt: '$rel' (salteada)"
      continue
    fi
    if [ -d "$src" ]; then
      log "copy    $rel_real/"
      [ "$DRY_RUN" -eq 1 ] || { mkdir -p "$TARGET/$rel_real"; cp -R "$src/." "$TARGET/$rel_real/"; }
      manifest_add_tree "$src"
    else
      log "copy    $rel_real"
      [ "$DRY_RUN" -eq 1 ] || { mkdir -p "$TARGET/$(dirname "$rel_real")"; cp "$src" "$TARGET/$rel_real"; }
      manifest_add "$rel_real"
    fi
    C_COPY=$((C_COPY + 1))
  done
}

# create-if-absent: never clobber project-owned config; offer a .kit-new for review
install_if_absent() {
  src=$1
  rel=$2
  if [ -e "$TARGET/$rel" ]; then
    if cmp -s "$src" "$TARGET/$rel"; then
      log "skip    $rel (idéntico al del kit)"
      C_SKIP=$((C_SKIP + 1))
    else
      log "conflict $rel → $rel.kit-new (ya existía; fusiona a mano)"
      C_CONFLICT=$((C_CONFLICT + 1))
      [ "$DRY_RUN" -eq 1 ] || cp "$src" "$TARGET/$rel.kit-new"
    fi
  else
    log "create  $rel"
    C_COPY=$((C_COPY + 1))
    [ "$DRY_RUN" -eq 1 ] || { mkdir -p "$TARGET/$(dirname "$rel")"; cp "$src" "$TARGET/$rel"; }
  fi
}

while IFS= read -r rel; do
  rel=${rel%%#*}                       # strip comments
  rel=$(printf '%s' "$rel" | sed -e 's/[[:space:]]*$//')
  [ -n "$rel" ] || continue
  copy_entry "$rel"
done < "$KIT_DIR/include.txt"

# Root config that must not be silently overwritten
install_if_absent "$KIT_ROOT/opencode.jsonc" "opencode.jsonc"
install_if_absent "$KIT_ROOT/AGENTS.md" "AGENTS.md"
install_if_absent "$KIT_ROOT/.env.example" ".env.example"
install_if_absent "$KIT_DIR/templates/gitignore" ".gitignore"

# Context is project-owned: seed only when absent, with placeholders resolved
seed_context() {
  src=$1
  rel=$2
  if [ -e "$TARGET/$rel" ]; then
    log "keep    $rel (estado del proyecto: intacto)"
    C_SKIP=$((C_SKIP + 1))
    return
  fi
  log "seed    $rel (contexto vacío)"
  C_SEED=$((C_SEED + 1))
  if [ "$DRY_RUN" -eq 1 ]; then return 0; fi
  mkdir -p "$TARGET/$(dirname "$rel")"
  sed -e "s/__DATE__/$TODAY/g" -e "s/__KIT_VERSION__/$KIT_VERSION/g" "$src" > "$TARGET/$rel"
}

seed_context "$KIT_DIR/templates/STATE.md" "docs/context/STATE.md"
seed_context "$KIT_DIR/templates/decisions-log.md" "docs/context/decisions-log.md"

# Install marker (also the signal that .opencode/ belongs to this kit)
if [ "$DRY_RUN" -eq 0 ]; then
  src_desc=${KIT_SOURCE_URL:-}
  if [ -z "$src_desc" ]; then
    src_desc="local:$KIT_ROOT"
    if command -v git >/dev/null 2>&1; then
      url=$(git -C "$KIT_ROOT" remote get-url origin 2>/dev/null || true)
      if [ -n "$url" ]; then src_desc=$url; fi
    fi
  fi
  ref_desc=${KIT_REF:-local}
  files_block=$(printf '%s' "$KIT_FILES" | sed -e '/^$/d' | sort -u \
    | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/^/    "/' -e 's/$/",/' \
    | sed -e '$ s/,$//')
  mkdir -p "$TARGET/.opencode"
  cat > "$TARGET/.opencode/kit.json" <<EOF
{
  "kit": "opencode-dev-team",
  "version": "$KIT_VERSION",
  "installed_at": "$TODAY",
  "source": "$src_desc",
  "ref": "$ref_desc",
  "manifest": "kit/include.txt",
  "files": [
$files_block
  ]
}
EOF
  log "write   .opencode/kit.json ($KIT_VERSION)"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
KIT_CLONE_REL=""
case "$KIT_ROOT/" in
  "$TARGET/"*) KIT_CLONE_REL=${KIT_ROOT#"$TARGET"/} ;;
esac
printf '\n%s\n' "resumen"
printf '  instalado/actualizado: %s\n' "$C_COPY"
printf '  contexto sembrado:     %s\n' "$C_SEED"
printf '  intacto/salteado:      %s\n' "$C_SKIP"
printf '  requiere tu revisión:  %s\n' "$C_CONFLICT"

if [ "$C_CONFLICT" -gt 0 ]; then
  printf '\n  Diff de los archivos .kit-new y fusiona lo que te sirva.\n'
fi

# The clone of the kit inside the project is just the vehicle: disposable now
if [ -n "$KIT_CLONE_REL" ]; then
  printf '\n  el kit quedó clonado en %s; ya está inyectado — puedes borrarlo:\n    rm -rf %s\n\n' "$KIT_CLONE_REL" "$KIT_CLONE_REL"
fi

cat <<EOF

próximos pasos
  cd $TARGET
  git add .opencode AGENTS.md opencode.jsonc docs .gitignore .env.example
  opencode

El primer agente es tech-lead. Revisa docs/context/STATE.md: arranca vacío a propósito.
EOF
