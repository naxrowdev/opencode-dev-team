#!/bin/sh
# selftest.sh — install the kit into throwaway directories and assert the contract:
#   1. a fresh install carries no kit-repository state and seeds empty context;
#   2. re-running never touches docs/context/* (write-once);
#   3. existing project config is preserved and offered as *.kit-new;
#   4. the installer refuses to run against the kit repo or a foreign .opencode/.
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

# ── Report ────────────────────────────────────────────────────────────────────
printf '\n%s\n' "─────────────────────────────"
printf 'passed: %s   failed: %s\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
printf 'selftest OK\n'
