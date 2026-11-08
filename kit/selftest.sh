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
check "models guide installed"                  test -f "$A/docs/guides/models-per-role.md"
check "empty tickets dir installed"             test -d "$A/docs/specs/tickets"
check "context seeded"                          test -f "$A/docs/context/STATE.md"
check "decisions-log seeded"                    test -f "$A/docs/context/decisions-log.md"

refute "STATE.md carries no kit history"        grep -q "naxrowdev\|repo publicado\|agentic dev team v0" "$A/docs/context/STATE.md"
refute "STATE.md has no unresolved placeholder" grep -q "__" "$A/docs/context/STATE.md"
refute "decisions-log carries no kit decisions" grep -q "Tech-lead con el usuario" "$A/docs/context/decisions-log.md"
refute "no .kit-new on a fresh install"         test -e "$A/opencode.jsonc.kit-new"

# Per-role models stay opt-in: the example block travels, but only as comments
check "model example block documented"           grep -q "Modelos por rol (OPCIONAL)" "$A/opencode.jsonc"
grep -vE '^[[:space:]]*//' "$A/opencode.jsonc" > "$WORK/opencode-active.jsonc"
refute "model example stays commented"           grep -q '"agents"' "$WORK/opencode-active.jsonc"

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

# Spanish neutrality: the prose that travels must not use voseo
VOSEO_RE='\b(Sos|vos|escribís|tenés|podés|hacés|querés|sabés|elegís|decís|venís|usás|tocás|mirás|pedís|buscás|leés|creés|decidés|seguís|consultás|evaluás|reportás|analizás|diseñás|priorizás|implementás|ejecutás|revisás|validás|configurás|definís|agregás|documentás|conectás|escribí|ejecutá|revisá|validá|aplicá|usá|configurá|definí|agregá|implementá|creá|generá|publicá|instalá|cargá|guardá|buscá|hacé|pedí|leé|corrí|documentá|diseñá|derivá|incluí|basá|editá|mergeá|analizá|reportá|devolvé|actualizá|versioná|priorizá|justificá|escuchá|clarificá|confirmá|decidí|partí|nombrá|entregá|dejá|esperá|ignorá|evità|consultá|rechazá|re-instalá|reiniciá|verificá|elegí|seguí|volvé|borrá|partila|cruzalo|parate|reemplazalo|inicialo|contrastalo|contrastala|castellano)\b'
refute "no voseo in the installed prose" \
  grep -rEl "$VOSEO_RE" "$A/.opencode/agents/" "$A/docs/" "$A/AGENTS.md" "$A/opencode.jsonc"

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

# ── 8. Curl mode: the installer bootstraps itself from a tarball ──────────────
# No network: a local tarball (GitHub-shaped: one top-level directory) plus
# ODT_TARBALL_URL=file:// exercises the real piped code path.
printf '\ncurl mode (self-bootstrap)\n'
H="$WORK/curl"
mkdir -p "$H/pack/opencode-dev-team"
cp -R "$KIT_ROOT/." "$H/pack/opencode-dev-team"
if tar czf "$H/kit.tar.gz" -C "$H/pack" opencode-dev-team 2>/dev/null; then
  ok "test tarball built"
else
  bad "test tarball built"
fi
if command -v sha256sum >/dev/null 2>&1; then
  SHA=$(sha256sum "$H/kit.tar.gz" | cut -d' ' -f1)
else
  SHA=$(shasum -a 256 "$H/kit.tar.gz" | cut -d' ' -f1)
fi

curl_mode() {   # curl_mode DIR LOG [installer args...]
  d=$1; log=$2; shift 2
  mkdir -p "$d"
  (cd "$d" && cat "$INSTALL" | ODT_TARBALL_URL="file://$H/kit.tar.gz" sh -s -- "$@" > "$log" 2>&1)
}

I="$H/installed"
if curl_mode "$I" "$WORK/curl.log" --ref vtest; then ok "curl mode installs"; else
  bad "curl mode installs"; cat "$WORK/curl.log"
fi
check "curl mode agents installed"              test -f "$I/.opencode/agents/tech-lead.md"
check "curl mode guide installed"               test -f "$I/docs/guides/models-per-role.md"
check "curl mode records source"                grep -q '"source": "https://github.com/naxrowdev/opencode-dev-team"' "$I/.opencode/kit.json"
check "curl mode records ref"                   grep -q '"ref": "vtest"' "$I/.opencode/kit.json"

J="$H/dry"
check "curl dry-run exit 0"                     curl_mode "$J" "$WORK/curl-dry.log" --ref vtest --dry-run
refute "curl dry-run writes nothing"            test -e "$J/AGENTS.md"

L="$H/goodsha"
check "curl accepts a matching checksum"        curl_mode "$L" "$WORK/curl-sha.log" --tarball "$H/kit.tar.gz" --sha256 "$SHA"
check "checksum install lands"                  test -f "$L/AGENTS.md"

K="$H/badsha"
refute "curl rejects a wrong checksum"          curl_mode "$K" "$WORK/curl-badsha.log" --tarball "$H/kit.tar.gz" --sha256 0000000000000000000000000000000000000000000000000000000000000000
check "checksum error explains itself"          grep -q "checksum no coincide" "$WORK/curl-badsha.log"
refute "checksum failure writes nothing"        test -e "$K/AGENTS.md"

mkdir -p "$H/badpack/x"
tar czf "$H/bad.tar.gz" -C "$H/badpack" x
refute "curl rejects a tarball without the kit" curl_mode "$H/badtar" "$WORK/curl-badtar.log" --tarball "$H/bad.tar.gz"
check "bad tarball error explains itself"       grep -q "no contiene kit/install.sh" "$WORK/curl-badtar.log"

check "curl help exits 0"                       curl_mode "$H/help" "$WORK/curl-help.log" --help
check "help documents curl mode"                grep -q "Curl mode only" "$WORK/curl-help.log"

refute "curl-only flag rejected in local mode"  run_install "$WORK/flag.log" "$H/localflag" --ref v1
check "local-mode error points to curl mode"    grep -q "solo aplica al modo curl" "$WORK/flag.log"

# ── 9. Uninstall: the manifest is the contract, and it never destroys your work ─
printf '\nuninstall (manifest-driven)\n'
UNINSTALL="$KIT_ROOT/kit/uninstall.sh"

run_uninstall() {   # run_uninstall DIR LOG [args...]
  d=$1; log=$2; shift 2
  "$UNINSTALL" "$d" "$@" >"$log" 2>&1
}

U="$WORK/uninstall"
mkdir -p "$U"
run_install "$WORK/u-install.log" "$U" >/dev/null 2>&1 || true

check "install writes a file manifest"          grep -q '"files"' "$U/.opencode/kit.json"
u_files=$(grep -c '^    "' "$U/.opencode/kit.json" || true)
check "manifest covers the kit tree"            test "$u_files" -gt 400
check "manifest lists an agent"                 grep -q '"\.opencode/agents/tech-lead\.md"' "$U/.opencode/kit.json"
refute "manifest excludes the seeded memory"   grep -qE 'docs/context/(STATE|decisions-log)\.md' "$U/.opencode/kit.json"
refute "manifest excludes the root config"      grep -q '"AGENTS\.md"' "$U/.opencode/kit.json"

# User-owned additions that must survive the uninstall
printf 'x\n' > "$U/.opencode/agents/mi-agente.md"
printf 'x\n' > "$U/.opencode/skills/mi-skill.md"
printf '\n<!-- sentinel -->\n' >> "$U/docs/context/STATE.md"
u_state=$(hash_of "$U/docs/context/STATE.md")
u_config=$(hash_of "$U/opencode.jsonc")

check "plan only exits 0"                       run_uninstall "$U" "$WORK/u-plan.log"
check "plan announces it deletes nothing"       grep -q "plan only" "$WORK/u-plan.log"
check "plan points at --yes"                    grep -q -- "--yes" "$WORK/u-plan.log"
check "plan leaves the kit installed"           test -f "$U/.opencode/agents/tech-lead.md"

refute "--yes and --dry-run are contradictory"  run_uninstall "$U" "$WORK/u-conflict.log" --yes --dry-run

if run_uninstall "$U" "$WORK/u-yes.log" --yes; then ok "uninstall --yes exits 0"; else
  bad "uninstall --yes exits 0"; cat "$WORK/u-yes.log"
fi
refute "kit-owned file deleted"                 test -e "$U/.opencode/agents/tech-lead.md"
refute "kit-owned skill deleted"                test -e "$U/.opencode/skills/stack-guard"
check "user agent preserved"                    test -f "$U/.opencode/agents/mi-agente.md"
check "user skill preserved"                    test -f "$U/.opencode/skills/mi-skill.md"
check "project memory preserved"                test -f "$U/docs/context/STATE.md"
check "project memory untouched"                test "$(hash_of "$U/docs/context/STATE.md")" = "$u_state"
check "root config preserved"                   test -f "$U/opencode.jsonc"
check "root config untouched"                   test "$(hash_of "$U/opencode.jsonc")" = "$u_config"
refute "marker removed"                         test -e "$U/.opencode/kit.json"
refute "second run refuses"                     run_uninstall "$U" "$WORK/u-again.log" --yes
check "second run explains itself"              grep -q "no está instalado" "$WORK/u-again.log"

# Explicit flags for the groups that are skipped by default
P="$WORK/uninstall-purge"
mkdir -p "$P"
run_install "$WORK/u-install2.log" "$P" >/dev/null 2>&1 || true
run_uninstall "$P" "$WORK/u-purge.log" --yes --purge-context --remove-root-config >/dev/null 2>&1 || true
refute "purge removes the project memory"       test -e "$P/docs/context/STATE.md"
refute "remove-root-config removes the config"  test -e "$P/opencode.jsonc"
refute "remove-root-config removes AGENTS.md"   test -e "$P/AGENTS.md"

# Installations from before the manifest: refuse instead of guessing
M="$WORK/uninstall-legacy"
mkdir -p "$M"
run_install "$WORK/u-install3.log" "$M" >/dev/null 2>&1 || true
sed -e '/^  "files": \[/,/^  \]/d' "$M/.opencode/kit.json" > "$M/.opencode/kit.json.tmp"
mv "$M/.opencode/kit.json.tmp" "$M/.opencode/kit.json"
refute "missing manifest refuses to run"        run_uninstall "$M" "$WORK/u-legacy.log" --yes
check "missing manifest explains the fix"       grep -q "no tiene manifiesto" "$WORK/u-legacy.log"
check "missing manifest deletes nothing"        test -f "$M/.opencode/agents/tech-lead.md"

# A tampered manifest must not escape the target
E="$WORK/uninstall-escape"
mkdir -p "$E" "$WORK/outside"
printf 'do not touch\n' > "$WORK/outside/victim.txt"
run_install "$WORK/u-install4.log" "$E" >/dev/null 2>&1 || true
sed -e 's|^  \]$|    "../outside/victim.txt",\n    "/etc/passwd",\n    ".opencode/../../outside/victim.txt"\n  ]|' \
  "$E/.opencode/kit.json" > "$E/.opencode/kit.json.tmp"
mv "$E/.opencode/kit.json.tmp" "$E/.opencode/kit.json"
run_uninstall "$E" "$WORK/u-escape.log" --yes >/dev/null 2>&1 || true
check "invalid manifest paths skipped"          grep -q "rutas inválidas" "$WORK/u-escape.log"
check "path traversal touches nothing outside"  grep -q "do not touch" "$WORK/outside/victim.txt"
check "traversal paths are skipped"             grep -q "\.\./outside/victim.txt" "$WORK/u-escape.log"

# The kit repo is never a valid uninstall target
refute "uninstalling the kit repo is refused"   run_uninstall "$KIT_ROOT" "$WORK/u-kitrepo.log" --yes
check "kit-repo guard explains itself"          grep -q "repo del kit" "$WORK/u-kitrepo.log"

# Full cycle: install → uninstall → install lands clean
C="$WORK/cycle"
mkdir -p "$C"
run_install "$WORK/c1.log" "$C" >/dev/null 2>&1 || true
run_uninstall "$C" "$WORK/c2.log" --yes >/dev/null 2>&1 || true
run_install "$WORK/c3.log" "$C" >/dev/null 2>&1 || true
check "cycle reinstalls the agents"             test -f "$C/.opencode/agents/tech-lead.md"
check "cycle reinstalls the marker"             test -f "$C/.opencode/kit.json"
check "cycle keeps the project memory"          test -f "$C/docs/context/STATE.md"

# ── Report ────────────────────────────────────────────────────────────────────
printf '\n%s\n' "─────────────────────────────"
printf 'passed: %s   failed: %s\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
printf 'selftest OK\n'
