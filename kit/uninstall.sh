#!/bin/sh
# uninstall.sh — remove the agentic dev team kit from a project.
#
#   kit/uninstall.sh [TARGET_DIR] [--yes] [--dry-run]
#                   [--purge-context] [--remove-root-config]
#
# Reads the install manifest (.opencode/kit.json → "files") and deletes exactly
# the files this kit wrote. It never guesses: files you added yourself, the
# project memory (docs/context/) and the root config stay in place unless you
# ask for them with an explicit flag.
#
# Default is PLAN ONLY: nothing is deleted without --yes.
# This script NEVER runs git, and never calls rm -rf.
#
# POSIX sh, no dependencies beyond the coreutils. Works from a clone or piped:
#   curl -fsSL <url>/kit/uninstall.sh | sh -s -- --yes

set -eu

TARGET="."
TARGET_GIVEN=0
APPLY=0
PLAN_ONLY=0
PURGE_CONTEXT=0
REMOVE_ROOT=0

usage() {
  cat <<'EOF'
Usage: kit/uninstall.sh [TARGET_DIR] [options]
       curl -fsSL <url>/kit/uninstall.sh | sh -s -- [options]

  TARGET_DIR            Project to clean. Omit it to use the current folder.
  --yes                 Actually delete. Without it, only the plan is printed.
  --dry-run             Explicit alias of the plan (default behaviour).
  --purge-context       Also delete docs/context/STATE.md and decisions-log.md
                        (the project memory). Never deleted by default.
  --remove-root-config  Also delete opencode.jsonc, AGENTS.md, .env.example and
                        .gitignore. Never deleted by default.
  -h, --help            Show this help.

Deletes only the files listed in .opencode/kit.json ("files"), then removes the
marker and any directory left empty (rmdir, never rm -rf). Files you added to
.opencode/ are not in the manifest and survive.
EOF
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

log() { printf '  %-7s %s\n' "$1" "$2"; }

# ── Args ──────────────────────────────────────────────────────────────────────
while [ $# -gt 0 ]; do
  case "$1" in
    --yes)                APPLY=1 ;;
    --dry-run)            PLAN_ONLY=1 ;;
    --purge-context)      PURGE_CONTEXT=1 ;;
    --remove-root-config) REMOVE_ROOT=1 ;;
    -h|--help)            usage; exit 0 ;;
    -*)                   die "opción desconocida: $1 (ver --help)" ;;
    *)
      case "$TARGET_GIVEN" in
        0) TARGET=$1; TARGET_GIVEN=1 ;;
        *) die "solo se acepta un TARGET_DIR" ;;
      esac
      ;;
  esac
  shift
done

if [ "$APPLY" -eq 1 ] && [ "$PLAN_ONLY" -eq 1 ]; then
  die "--yes y --dry-run se contradicen; elige uno"
fi

# ── Guard the target ──────────────────────────────────────────────────────────
[ -d "$TARGET" ] || die "no existe el destino: $TARGET"
TARGET_ABS=$(CDPATH= cd -- "$TARGET" && pwd)

case "$TARGET" in
  /ruta|*/ruta/*|/path/to/*|/your/*)
    die "el destino '$TARGET' parece un placeholder de la documentación; usa la ruta real de tu proyecto"
    ;;
esac

[ "$TARGET_ABS" != "/" ] || die "me niego a desinstalar sobre / — indica el proyecto concreto"

# The kit repository itself is not an installed project
if [ -f "$TARGET_ABS/kit/install.sh" ] && [ -d "$TARGET_ABS/.opencode/agents" ]; then
  die "el destino es el repo del kit, no un proyecto instalado; no hay nada que desinstalar aquí"
fi

MARKER="$TARGET_ABS/.opencode/kit.json"
[ -f "$MARKER" ] || die "el kit no está instalado en $TARGET_ABS (falta .opencode/kit.json)"

grep -q '"kit"[[:space:]]*:[[:space:]]*"opencode-dev-team"' "$MARKER" \
  || die "el marcador $MARKER no corresponde a este kit; revísalo a mano"

if ! grep -q '"files"[[:space:]]*:' "$MARKER"; then
  die "el .opencode/kit.json no tiene manifiesto (instalación anterior a 1.0.0), así que no sé qué archivos son del kit. Vuelve a instalar con la versión actual y reintenta — la re-instalación es idempotente y genera el manifiesto."
fi

field() {
  sed -n "s/^[[:space:]]*\"$1\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" "$MARKER" | head -n 1
}
KIT_VERSION=$(field version)
INSTALLED_AT=$(field installed_at)

# ── Manifest ──────────────────────────────────────────────────────────────────
MANIFEST=$(sed -n '/"files"[[:space:]]*:[[:space:]]*\[/,/^[[:space:]]*\]/p' "$MARKER" \
  | sed -e '1d' -e '$d' \
  | sed -n 's/^[[:space:]]*"\([^"]*\)"[[:space:]]*,\{0,1\}[[:space:]]*$/\1/p' \
  | sort -u)

if [ -z "$MANIFEST" ]; then
  die "el manifiesto de $MARKER está vacío; no hay nada que borrar (¿instalación incompleta?)"
fi

safe_rel() {
  case "$1" in
    ""|.|./|/|/*) return 1 ;;
  esac
  case "/$1/" in
    */../*) return 1 ;;
  esac
  return 0
}

# ── Plan ──────────────────────────────────────────────────────────────────────
printf 'desinstalando opencode-dev-team %s (instalado %s)\n' "$KIT_VERSION" "$INSTALLED_AT"
printf '  destino: %s\n\n' "$TARGET_ABS"

COUNT_DEL=0
COUNT_MISSING=0
COUNT_SKIP=0
COUNT_FAIL=0
SKIPPED=""
DIRS=""

add_dirs() {
  d=$(dirname "$1")
  while [ "$d" != "." ] && [ "$d" != "/" ] && [ -n "$d" ]; do
    DIRS="${DIRS}${d}
"
    d=$(dirname "$d")
  done
}

collect() {          # collect REL — prints and deletes one kit-owned path
  rel=$1
  if ! safe_rel "$rel"; then
    COUNT_SKIP=$((COUNT_SKIP + 1))
    SKIPPED="${SKIPPED}${rel}
"
    return 0
  fi
  path="$TARGET_ABS/$rel"
  if [ ! -e "$path" ] && [ ! -L "$path" ]; then
    log "gone" "$rel (ya no existe)"
    COUNT_MISSING=$((COUNT_MISSING + 1))
    return 0
  fi
  if [ "$APPLY" -eq 1 ]; then
    if rm -f "$path"; then
      log "delete" "$rel"
      COUNT_DEL=$((COUNT_DEL + 1))
    else
      log "FAIL" "$rel (no se pudo borrar)"
      COUNT_FAIL=$((COUNT_FAIL + 1))
    fi
  else
    log "delete" "$rel"
    COUNT_DEL=$((COUNT_DEL + 1))
  fi
  add_dirs "$rel"
}

printf 'manifiesto\n'
while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  collect "$rel"
done <<EOF
$MANIFEST
EOF

# ── Optional groups: never touched without an explicit flag ───────────────────
printf '\nopcionales\n'
CONTEXT_FILES="docs/context/STATE.md
docs/context/decisions-log.md"
if [ "$PURGE_CONTEXT" -eq 1 ]; then
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    collect "$rel"
  done <<EOF
$CONTEXT_FILES
EOF
else
  log "keep" "docs/context/STATE.md y decisions-log.md (memoria del proyecto; usa --purge-context para borrarla)"
fi

ROOT_FILES="opencode.jsonc
AGENTS.md
.env.example
.gitignore"
if [ "$REMOVE_ROOT" -eq 1 ]; then
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    collect "$rel"
  done <<EOF
$ROOT_FILES
EOF
else
  log "keep" "opencode.jsonc, AGENTS.md, .env.example, .gitignore (config del proyecto; usa --remove-root-config)"
fi

# ── Marker and empty directories (rmdir only) ─────────────────────────────────
printf '\nmarcador\n'
if [ "$APPLY" -eq 1 ]; then
  if rm -f "$MARKER"; then
    log "delete" ".opencode/kit.json"
    COUNT_DEL=$((COUNT_DEL + 1))
  else
    log "FAIL" ".opencode/kit.json (no se pudo borrar)"
    COUNT_FAIL=$((COUNT_FAIL + 1))
  fi
else
  log "delete" ".opencode/kit.json"
  COUNT_DEL=$((COUNT_DEL + 1))
fi
DIRS="${DIRS}.opencode
"

if [ "$APPLY" -eq 1 ]; then
  for d in $(printf '%s' "$DIRS" | sed -e '/^$/d' | sort -ru); do
    case "$d" in ""|.|/|.opencode/..|..) continue ;; esac
    if [ -d "$TARGET_ABS/$d" ] && rmdir "$TARGET_ABS/$d" 2>/dev/null; then
      log "rmdir" "$d"
    fi
  done
fi

# ── Summary ───────────────────────────────────────────────────────────────────
printf '\n%s\n' "resumen"
printf '  borrados:              %s\n' "$COUNT_DEL"
printf '  ya no existían:        %s\n' "$COUNT_MISSING"
printf '  rutas inválidas:       %s\n' "$COUNT_SKIP"
printf '  errores:               %s\n' "$COUNT_FAIL"
if [ -n "$SKIPPED" ]; then
  printf '\n  rutas inválidas en el manifiesto (salteadas, no se tocó nada):\n'
  printf '%s' "$SKIPPED" | sed -e '/^$/d' | sed -e 's/^/    /'
fi

if [ "$APPLY" -eq 0 ]; then
  cat <<EOF

plan only: no se borró nada.
  ejecuta el mismo comando con --yes para aplicar.
EOF
  exit 0
fi

cat <<EOF

listo. Revisa el resultado y confirma con git:
  cd $TARGET_ABS
  git status --short
  git diff --stat
EOF

[ "$COUNT_FAIL" -eq 0 ] || exit 1
exit 0
