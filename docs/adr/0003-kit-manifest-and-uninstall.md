# ADR-0003: Install Manifest and Manifest-Driven Uninstall

## Status

Accepted

## Context

Installing the kit copies roughly 450 kit-owned files into the target project
(`.opencode/agents/`, `.opencode/skills/`, the `docs/*/README.md` set), seeds
`docs/context/`, and creates the root config when absent. There was no record of what
was installed: re-running the installer already had to rely on the `include.txt`
manifest, but the project had no way to tell kit-owned files apart from files its own
team added next to them (`.opencode/agents/mi-agente.md`, an extra skill, a rewritten
`docs/specs/README.md`).

A one-shot `rm -rf .opencode` would delete user work, and `git clean` would delete
untracked project files. Neither is acceptable for a tool that will run in other
people's repositories and will be published at 1.0.0.

## Decision

The installer records what it wrote, and a separate uninstaller deletes exactly that.

### Manifest

`.opencode/kit.json` gains a `files` array with the relative paths of every kit-owned
file:

```json
{
  "kit": "opencode-dev-team",
  "version": "1.0.0",
  "installed_at": "2026-11-07",
  "source": "https://github.com/<owner>/<repo>",
  "ref": "v1.0.0",
  "manifest": "kit/include.txt",
  "files": [".opencode/agents/tech-lead.md", ".opencode/skills/stack-guard/SKILL.md"]
}
```

Details of the contract:

- The list is computed from the **source tree** that `include.txt` selects, not by
  scanning the target. Files the project added are simply not there.
- The seeded memory (`docs/context/STATE.md`, `docs/context/decisions-log.md`) is
  excluded: it is project memory, written once, never kit-owned. The kit's
  `docs/context/README.md` is documentation, so it does travel and is listed.
- The root config (`opencode.jsonc`, `AGENTS.md`, `.env.example`, `.gitignore`) is
  excluded: it is created only when absent and then belongs to the project.
- No new dependency: the array is emitted with `sed`/`sort` from the paths collected
  while copying; the uninstaller reads it back with `sed`.
- Re-running the installer regenerates the manifest, so an update also refreshes it.

### `kit/uninstall.sh`

A separate, self-contained script (no kit tree, no network, works when piped):

- **Plan by default.** Without `--yes` it prints what it would delete and exits 0.
  `--dry-run` is an explicit alias for the same behaviour. `--yes` with `--dry-run`
  is rejected as contradictory.
- **Manifest only.** It deletes the paths in `files`, nothing else. Each path must be
  relative and must not contain a `..` segment; invalid entries are skipped with a
  warning and listed in the summary.
- **`rmdir`, never `rm -rf`.** After deleting files it removes directories that are
  empty, deepest first. A directory the user still uses survives, and no recursive
  delete ever runs.
- **Explicit opt-in for the two groups that are not kit-owned**:
  `--purge-context` (deletes the seeded `docs/context/STATE.md` and
  `decisions-log.md`) and `--remove-root-config` (deletes the four root files).
  Neither happens by default.
- **Marker last.** `.opencode/kit.json` is deleted at the end; a second run stops with
  "el kit no está instalado".
- **Refuses to guess.** An installation without `files` (anything installed before
  1.0.0) is refused with a message asking to reinstall with the current version first.
  The installer is idempotent, so that is safe.
- **No git.** It prints the `git status --short` / `git diff --stat` commands for the
  user to review the deletion.

## Alternatives considered

- **`rm -rf .opencode` and the seeded docs**: simple, catastrophic for any project that
  customized its agents or added its own. It also erases the whole `.opencode/`, which
  may contain unrelated tooling.
- **Heuristics** (delete `*.md` in `.opencode/agents`, anything matching a skill name):
  unknowable at the edges, and silently wrong when the kit renames or removes a file.
- **`git clean` / `git restore`**: the target project may not be a git repository, may
  have uncommitted work, and the kit files may be committed alongside project files.
- **A list of "known kit files" hardcoded in the uninstaller**: it drifts from the
  release that was actually installed, and requires shipping the old lists forever.
- **`install.sh --uninstall` instead of a separate script**: one file to maintain, but
  a destructive operation mixed into the installer; the user asked for a dedicated
  command.
- **Uninstall via the curl-mode bootstrap**: would need the kit tree for no reason; the
  manifest is already in the project.

## Consequences

- Uninstalling is safe on a project that customized its agents, added skills, or wrote
  its own docs: those survive, and `git status` shows exactly what changed.
- Files that an older kit version published and a newer one stopped shipping are not in
  the manifest and survive the uninstall, just as the installer does not prune them.
  They are listed as a known limit in the guide and deleted by hand.
- The manifest is a mutable file in the project: if a user edits it, the uninstaller
  trusts it (after path validation). Tampering can only delete files inside the target.
- Installations made before 1.0.0 must be reinstalled once before they can be
  uninstalled. That is documented in the guide and covered by a selftest assertion.
- The selftest grows from 73 to 109 assertions: manifest contents, plan-only behaviour,
  preservation of user files, project memory and root config, the two optional flags,
  the legacy-marker refusal, path-traversal skipping, the kit-repo guard, and a full
  install → uninstall → install cycle.
