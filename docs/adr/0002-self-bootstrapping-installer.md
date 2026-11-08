# ADR-0002: Self-Bootstrapping Installer for One-Command Install and Update

## Status

Accepted

## Context

Distributing the kit required `git`: clone the repository inside the target project, run
`kit/install.sh`, then delete the clone. That works, but it adds three steps, leaves a
nested repository in the project while it runs, and requires `git` on machines that only
need the agent configuration. The user asked for a `curl` one-liner, and for it to point
at `install.sh` itself instead of a second script.

`kit/install.sh` cannot simply be piped: it resolves `KIT_ROOT` from `$0` and reads the
whole tree (`VERSION`, `kit/include.txt`, `kit/templates/`, `.opencode/agents`,
`.opencode/skills`). Piped to `sh`, `$0` is the shell and none of those paths exist.

## Decision

Keep a single file, `kit/install.sh`, with two modes:

- **Local mode** (unchanged): the script finds its kit tree next to itself and installs
  from disk.
- **Curl mode**: when the kit assets are not next to `$0`, the script downloads a release
  tarball into `mktemp -d`, verifies it (`--sha256`, optional), extracts it, runs that copy
  with the same arguments, and removes the temp directory on exit.

Mode detection is based on the assets being present, not on an environment variable. The
extracted copy always has them, so the bootstrap cannot recurse.

Piped use:

```sh
curl -fsSL https://raw.githubusercontent.com/<owner>/<repo>/main/kit/install.sh | sh
curl -fsSL .../main/kit/install.sh | sh -s -- --ref v1.0.0 --dry-run
```

Details of the decision:

- **Latest stable without an API call**: GitHub redirects
  `https://github.com/<repo>/releases/latest` to the tag page. The script reads the
  `Location` value (`curl -w '%{redirect_url}'`), so there is no `api.github.com` request,
  no rate limit, and no JSON parsing. A repository with tags but no Release does not
  redirect; the script fails with a message that asks for `--ref` instead of silently
  installing `main`.
- **Curl-only flags**: `--ref`, `--sha256`, `--tarball` and `--repo` are rejected in local
  mode with a message that names curl mode, so they are never silently ignored.
  `--tarball` also serves air-gapped installs and the hermetic selftest.
- **Provenance**: `.opencode/kit.json` gains `ref`, and `source` now comes from
  `KIT_SOURCE_URL` when the installer runs from a downloaded tarball (otherwise the git
  remote or `local:<path>`, as before).
- **Testing stays offline**: the selftest builds a GitHub-shaped tarball of the working
  tree and exercises the real piped path through `ODT_TARBALL_URL=file://`.

## Alternatives considered

- **Separate `kit/bootstrap.sh`**: two files to document and two URLs to keep alive. The
  user explicitly asked for `install.sh` as the curl target.
- **Piping `install.sh` unchanged**: impossible without the tree; it would fail on
  `VERSION` and `kit/include.txt`.
- **Self-extracting script with a base64 payload**: would embed ~930 KB of agents and
  skills in the script, growing the repository on every revision with binary-like diffs.
- **`npx` package**: already deferred as a 0.3 candidate; it adds a Node requirement to a
  kit whose runtime is `sh` + coreutils.
- **GitHub API for the latest tag**: adds a rate-limited dependency and JSON parsing
  without `jq`; the redirect provides the same answer with plain `curl`.
- **Release assets (`releases/latest/download/kit.tar.gz` + `SHA256SUMS`)**: the natural
  next step; it removes the redirect hop and publishes a checksum to pin against. Deferred
  until releases exist, together with the hash/3-way upgrade work already tracked for 0.3.

## Consequences

- Installing and updating become the same single command, with no clone and no `git`
  requirement. The clone flow remains available and tested for air-gapped setups.
- Supply chain surface grows: `curl | sh` executes remote code, and the kit grants agents
  shell and edit permissions. Mitigations are HTTPS with `-f`, tag pinning via `--ref`,
  optional `--sha256`, and a documented download-review-run variant. Releases are not
  signed.
- Every published tag needs a GitHub Release, or "latest" does not resolve; the
  publication guide documents this.
- `install.sh` now carries two responsibilities. The local-mode body was left untouched
  and the existing selftest assertions still cover it.
- Until the repository is pushed and the first Release is published, the curl path cannot
  be validated end-to-end; it is tested with local tarballs only.
