#!/bin/sh
# install.sh — install the agentic dev team kit into a target project.
#
#   kit/install.sh [TARGET_DIR] [--dry-run] [--force]
#
# Copies the kit-owned files (.opencode/agents, .opencode/skills, docs READMEs),
# seeds an EMPTY project context from kit/templates/, and never carries over the
# kit repository's own state (its STATE.md, decisions-log.md, README, CHANGELOG).
#
# Safe to re-run: kit-owned files are refreshed, docs/context/* is write-once.
# This script NEVER runs git. See docs/guides/installing-into-a-project.md.
#
# POSIX sh, no dependencies beyond the coreutils.

set -eu

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

usage() {
  cat <<'EOF'
Usage: kit/install.sh [TARGET_DIR] [options]

  TARGET_DIR   Project to install into. Omit it to install into the folder
               you are in (recommended: cd into your project first).
  --dry-run    Print the plan, write nothing.
  --force      Overwrite a .opencode/ that was not installed by this kit.
  -h, --help   Show this help.

Copies kit-owned files, seeds an empty docs/context/, and refreshes
.opencode/kit.json. Never touches docs/context/ if it already exists.
EOF
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

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
    die "el destino '$TARGET' parece un placeholder de la documentación — reemplazalo por la ruta real de tu proyecto (ej.: $HOME/Proyectos/mi-proyecto)"
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
  die "el destino es el propio clon del kit (tiene kit/install.sh) — ejecutá el instalador desde la raíz de tu proyecto, sin entrar al clon"
fi
case "$TARGET/" in
  "$KIT_ROOT/"*) die "el destino está dentro del repo del kit ($KIT_ROOT) — elegí otro directorio" ;;
esac
case "$TARGET" in
  */.git|*/.git/*) die "el destino apunta a un directorio .git" ;;
esac

if [ "$DRY_RUN" -eq 0 ] && [ -d "$TARGET/.opencode" ] && [ ! -f "$TARGET/.opencode/kit.json" ] && [ "$FORCE" -eq 0 ]; then
  die "ya existe .opencode/ y no lo instaló este kit; usá --force para sobrescribirlo"
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
    else
      log "copy    $rel_real"
      [ "$DRY_RUN" -eq 1 ] || { mkdir -p "$TARGET/$(dirname "$rel_real")"; cp "$src" "$TARGET/$rel_real"; }
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
      log "conflict $rel → $rel.kit-new (ya existía; mergeá a mano)"
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
  src_desc="local:$KIT_ROOT"
  if command -v git >/dev/null 2>&1; then
    url=$(git -C "$KIT_ROOT" remote get-url origin 2>/dev/null || true)
    if [ -n "$url" ]; then src_desc=$url; fi
  fi
  mkdir -p "$TARGET/.opencode"
  cat > "$TARGET/.opencode/kit.json" <<EOF
{
  "kit": "opencode-dev-team",
  "version": "$KIT_VERSION",
  "installed_at": "$TODAY",
  "source": "$src_desc",
  "manifest": "kit/include.txt"
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
  printf '\n  Diff de los archivos .kit-new y mergeá lo que te sirva.\n'
fi

# The clone of the kit inside the project is just the vehicle: disposable now
if [ -n "$KIT_CLONE_REL" ]; then
  printf '\n  el kit quedó clonado en %s; ya está inyectado — podés borrarlo:\n    rm -rf %s\n\n' "$KIT_CLONE_REL" "$KIT_CLONE_REL"
fi

cat <<EOF

próximos pasos
  cd $TARGET
  git add .opencode AGENTS.md opencode.jsonc docs .gitignore .env.example
  opencode

El primer agente es tech-lead. Revisá docs/context/STATE.md: arranca vacío a propósito.
EOF
