#!/bin/sh
# selftest.sh — install the kit into throwaway directories and assert the contract:
#   1. a fresh install carries no kit-repository state and seeds empty context;
#   2. re-running never touches docs/context/* (write-once);
#   3. existing project config is preserved and offered as *.kit-new;
#   4. the installer refuses to run against the kit repo or a foreign .opencode/;
#   5. pasted documentation-placeholder targets are refused with a clear message,
#      and a mkdir failure explains itself instead of leaking a raw error;
#   6. omitting TARGET_DIR installs into the current directory (the primary flow);
#   7. a kit clone inside the project installs into the project root, prints a
#      cleanup hint, and installing into the clone itself is refused.
#
# POSIX sh, no dependencies beyond the coreutils. Run from anywhere:
#   kit/selftest.sh
set -eu

KIT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
INSTALL="$KIT_ROOT/kit/install.sh"
WORK_ROOT=${TMPDIR:-/tmp}/opencode
mkdir -p "$WORK_ROOT"
WORK=$(mktemp -d "$WORK_ROOT/kit-selftest.XXXXXX")
trap 'rm -rf "$WORK"' EXIT

PASS=0
FAIL=0

ok()  { printf '  ok    %s\n' "$1"; PASS=$((PASS + 1)); }
bad() { printf '  FAIL  %s\n' "$1"; FAIL=$((FAIL + 1)); }

check()  { desc=$1; shift; if "$@" >/dev/null 2>&1; then ok "$desc"; else bad "$desc"; fi; }
refute() { desc=$1; shift; if "$@" >/dev/null 2>&1; then bad "$desc"; else ok "$desc"; fi; }

hash_of() {
  if command -v md5sum >/dev/null 2>&1; then md5sum "$1" | cut -d' ' -f1
  else md5 -q "$1"; fi
}

run_install() {
  log=$1; shift
  if "$INSTALL" "$@" >"$log" 2>&1; then return 0; fi
  return 1
}

run_install_cwd() {
  d=$1; log=$2; shift 2
  (cd "$d" && "$INSTALL" "$@" >"$log" 2>&1)
}

run_install_local() {
  d=$1; kitdir=$2; log=$3; shift 3
  (cd "$d" && sh "$kitdir/kit/install.sh" "$@" >"$log" 2>&1)
}

printf 'selftest: opencode-dev-team kit\n\n'

# ── 1. Fresh install ──────────────────────────────────────────────────────────
printf 'fresh install\n'
A="$WORK/fresh"
mkdir -p "$A"
if run_install "$WORK/fresh.log" "$A"; then
  ok "installer exit 0"
else
  bad "installer exit 0"
  printf '\n--- install log ---\n'; cat "$WORK/fresh.log"; printf -- '---\n'
fi

check "AGENTS.md installed"                     test -f "$A/AGENTS.md"
check "opencode.jsonc installed"                test -f "$A/opencode.jsonc"
check ".env.example installed"                  test -f "$A/.env.example"
check ".gitignore installed"                    test -f "$A/.gitignore"
check "kit.json marker installed"               test -f "$A/.opencode/kit.json"
check "agents installed"                        test -f "$A/.opencode/agents/tech-lead.md"
check "skills installed"                        test -f "$A/.opencode/skills/stack-guard/SKILL.md"
check "docs tree installed"                     test -f "$A/docs/specs/README.md"
check "empty tickets dir installed"             test -d "$A/docs/specs/tickets"
check "context seeded"                          test -f "$A/docs/context/STATE.md"
check "decisions-log seeded"                    test -f "$A/docs/context/decisions-log.md"

refute "STATE.md carries no kit history"        grep -q "naxrowdev\|repo publicado\|agentic dev team v0" "$A/docs/context/STATE.md"
refute "STATE.md has no unresolved placeholder" grep -q "__" "$A/docs/context/STATE.md"
refute "decisions-log carries no kit decisions" grep -q "Tech-lead con el usuario" "$A/docs/context/decisions-log.md"
refute "no .kit-new on a fresh install"         test -e "$A/opencode.jsonc.kit-new"

# nothing from exclude.txt may travel
while IFS= read -r ex; do
  [ -n "$ex" ] || continue
  refute "excluded path not installed: $ex"     test -e "$A/$ex"
done <<EOF
$(sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$KIT_ROOT/kit/exclude.txt")
EOF

# every instructions path must resolve in the target
for p in $(sed -n 's/.*"instructions"[[:space:]]*:[[:space:]]*\[\([^]]*\)\].*/\1/p' "$A/opencode.jsonc" | tr -d '"' | tr ',' ' '); do
  check "instructions path resolves: $p"        test -e "$A/$p"
done

# ── 2. Re-run: context is write-once ──────────────────────────────────────────
printf '\n%s\n' 're-run and context immutability'
printf '\n<!-- sentinel: project-owned -->\n' >> "$A/docs/context/STATE.md"
before_state=$(hash_of "$A/docs/context/STATE.md")
before_agents=$(hash_of "$A/.opencode/agents/tech-lead.md")

if run_install "$WORK/rerun.log" "$A"; then ok "re-run exit 0"; else
  bad "re-run exit 0"; cat "$WORK/rerun.log"
fi

check "context untouched by re-run"             test "$(hash_of "$A/docs/context/STATE.md")" = "$before_state"
check "project sentinel survived"               grep -q "sentinel: project-owned" "$A/docs/context/STATE.md"
check "kit files refreshed by re-run"           test "$(hash_of "$A/.opencode/agents/tech-lead.md")" = "$before_agents"

# ── 3. Pre-existing project config is preserved ───────────────────────────────
printf '\nexisting config in target\n'
B="$WORK/existing"
mkdir -p "$B"
printf '# my own rules\n' > "$B/AGENTS.md"
if run_install "$WORK/existing.log" "$B"; then ok "install over existing config exit 0"; else
  bad "install over existing config exit 0"; cat "$WORK/existing.log"
fi
check "existing AGENTS.md preserved"            grep -q "my own rules" "$B/AGENTS.md"
check "AGENTS.md.kit-new offered"               test -f "$B/AGENTS.md.kit-new"

# ── 4. Guards ─────────────────────────────────────────────────────────────────
printf '\nguards\n'
refute "refuses to install into the kit repo"   run_install "$WORK/guard-kit.log" "$KIT_ROOT"

C="$WORK/foreign"
mkdir -p "$C/.opencode/agents"
printf 'name: mine\n' > "$C/.opencode/agents/mine.md"
refute "refuses a foreign .opencode/ without --force" run_install "$WORK/guard-foreign.log" "$C"
check "--force overrides the foreign .opencode/ guard" run_install "$WORK/guard-force.log" --force "$C"

# ── 5. Documentation placeholder + mkdir failure messages ─────────────────────
printf '\ndocumentation placeholder and mkdir failure\n'
refute "rejects the guide placeholder path"            run_install "$WORK/guard-placeholder.log" /ruta/a/mi-proyecto
check "placeholder error names the pasted path"       grep -q "/ruta/a/mi-proyecto" "$WORK/guard-placeholder.log"
check "placeholder error tells the user what to do"   grep -q "placeholder de la documentación" "$WORK/guard-placeholder.log"

F="$WORK/afile"
printf 'x' > "$F"
refute "refuses a target under a regular file"        run_install "$WORK/guard-mkdir.log" "$F/sub"
check "mkdir failure explains itself"                 grep -q "no se pudo crear el destino" "$WORK/guard-mkdir.log"

# ── 6. No-argument install targets the current directory ──────────────────────
printf '\ninstall without TARGET_DIR\n'
D="$WORK/noarg"
mkdir -p "$D"
check "no-arg dry-run works in cwd"                   run_install_cwd "$D" "$WORK/noarg-dry.log" --dry-run
refute "no-arg dry-run wrote nothing"                 test -e "$D/AGENTS.md"
check "no-arg real install runs in cwd"               run_install_cwd "$D" "$WORK/noarg.log"
check "landed in the working directory"               test -f "$D/AGENTS.md"
check "marker landed in the working directory"        test -f "$D/.opencode/kit.json"

# ── 7. Kit cloned inside the target project (primary flow) ────────────────────
printf '\nkit cloned inside the target\n'
G="$WORK/kitclone"
mkdir -p "$G"
cp -R "$KIT_ROOT" "$G/opencode-dev-team"   # working tree, not HEAD: the tests exercise the new code
check "clone ready (selfsetup)"                       test -f "$G/opencode-dev-team/kit/install.sh"
check "install from the project root"                 run_install_local "$G" "opencode-dev-team" "$WORK/kitclone.log"
check "kit files landed in the project root"          test -f "$G/AGENTS.md"
check "cleanup hint printed"                          grep -q "rm -rf" "$WORK/kitclone.log"
refute "installing into the clone itself refused"     run_install_local "$G" "opencode-dev-team" "$WORK/kitclone-guard.log" "$G/opencode-dev-team"
check "kit-clone guard explains itself"               grep -q "clon del kit" "$WORK/kitclone-guard.log"

# ── Report ────────────────────────────────────────────────────────────────────
printf '\n%s\n' "─────────────────────────────"
printf 'passed: %s   failed: %s\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
printf 'selftest OK\n'
