# Google Antigravity CLI (`agy`) Salt module

Adds a new masterless Salt formula at `google/antigravity/cli/` that installs the Google Antigravity CLI binary (`agy`) on Ubuntu/Linux workstations, mirroring the existing `oh-my-pi/cli/` module. Because the download URL carries an opaque GCS build-id suffix and the sha512 lives in a per-platform JSON manifest, the install can't use the usual `file.managed` + `source_hash` pattern; instead it fetches the manifest at apply time, downloads the tarball, verifies sha512, and extracts the `antigravity` member as `agy` into a versioned dir with a `/usr/local/bin/agy` symlink. The change registers `google.antigravity.cli` in `top.sls` and adds the `google:antigravity:cli:enabled` toggle to `pillar.sls.example`.

Watch for: nothing blocking. The sha512 verification is present and fails on mismatch (confirmed); completion is disabled by default and `onlyif`-guarded so it cannot fail the highstate (confirmed); all four naming surfaces (dir, pillar path, defaults key, top entry) agree (confirmed).

**Verdict**: APPROVED

## High-level view

The module follows the project's module convention precisely. `map.jinja` merges `defaults.yaml` (top key `antigravity`) with pillar path `google:antigravity:cli` using the same `pillar.get(..., merge=True)` pattern as `oh-my-pi/cli/map.jinja`; `init.sls` routes to `.install` or `.teardown` on the `enabled` flag. The four naming surfaces — directory `google/antigravity/cli`, pillar path `google:antigravity:cli`, defaults top key `antigravity`, and top.sls entry `google.antigravity.cli` — all agree, so Salt resolves the state path correctly from the top file.

The install departs from oh-my-pi only where the upstream distribution forces it: the URL and checksum come from a per-platform manifest fetched at apply time, so the download/verify/extract is one `cmd.run` block guarded by `creates:` for idempotency rather than a `file.managed`. The security-critical sha512 check uses `sha512sum -c -`, which exits non-zero on mismatch and (under `set -e`) aborts the state — verification is not skipped. The tarball member `antigravity` is installed as `agy`.

Shell completion is the one unverified area: no `agy completion` subcommand is documented upstream, so `defaults.yaml` ships `completion: false` and the completion state is both render-gated on the flag and `onlyif`-guarded, meaning it cannot fail a highstate even if a user flips the flag. Teardown removes the completion file, the symlink, and the versioned install dir via `file.absent`. The coder recorded `salt-call --local state.show_sls` as passing verification in the commit message.

<details>
<summary>Issues (1)</summary>

1. **Tarball layout assumption (possible)** — `install.sls` assumes the tarball's `antigravity` binary sits at the archive root (`$TMPDIR/antigravity`). If a future release nests it under a subdir, the `install` step fails. Non-blocking; noted in the plan's known-gaps and self-correcting (the state errors loudly rather than installing something wrong).

</details>

<details>
<summary>Details</summary>

### Apply-time manifest lookup vs render-time hardcoding

Unlike `oh-my-pi/cli/install.sls`, which hardcodes `source` and `source_hash` URLs built from the version, this module cannot: the Antigravity GCS object URL contains an opaque build-id and the sha512 is published in a per-platform JSON manifest. The module resolves both at apply time inside a single `cmd.run`:

```
MANIFEST="$(curl -fsSL '<manifest_url>')"
URL="$(... grep/sed for "url" ...)"
SHA="$(... grep/sed for "sha512" ...)"
if [ -z "$URL" ] || [ -z "$SHA" ]; then ... exit 1; fi
curl -fsSL "$URL" -o "$TMPDIR/cli.tar.gz"
echo "$SHA  $TMPDIR/cli.tar.gz" | sha512sum -c -
tar -xzf "$TMPDIR/cli.tar.gz" -C "$TMPDIR"
install -o root -g root -m 0755 "$TMPDIR/antigravity" '<agy_bin>'
```

It is the only approach that keeps the mandatory checksum verification while handling the opaque URL. The block runs under `set -e` with a `trap ... EXIT` temp-dir cleanup, is guarded by `creates: <agy_bin>`, and `require`s the install dir. Arch detection maps `cpuarch` to `linux_amd64`/`linux_arm64` and appends `_musl` when the corresponding musl libc exists.

### sha512 verification fails closed

The security check is `echo "$SHA  $TMPDIR/cli.tar.gz" | sha512sum -c -`. On a checksum mismatch `sha512sum -c` exits non-zero, and under `set -e` the whole `cmd.run` fails — the binary is never installed. There is no `skip_verify`, no `--insecure`, no fallback that swallows the error. Fail-closed, as required. If the manifest can't be fetched or either key is empty, the block also exits 1 rather than proceeding without a checksum.

### Completion is unverified but cannot break the highstate

No `agy completion` subcommand is documented upstream. Two guards keep this from failing a highstate: the state renders only when `antigravity.completion` is true (default `false`), and even then its `onlyif: <bin_dir>/agy completion bash >/dev/null 2>&1` skips the `cmd.run` unless the probe succeeds. A user flipping the flag on a build without that subcommand gets a skipped state, not a failure. This matches the task's instruction not to ship a completion command that could fail unverified.

### Verification evidence

The commit message records `sudo salt-call --local state.show_sls google.antigravity.cli` rendering cleanly: teardown states with `enabled: false`, and the install-dir/download/symlink states with `enabled: true`, with the manifest URL resolving to `linux_amd64.json` on x86_64. Per the task instruction I did not re-run this. I cross-checked the merge pattern, pillar nesting, and top.sls indentation against the `oh-my-pi/cli` reference by reading the files.

</details>

<details>
<summary>Files changed</summary>

- `google/antigravity/cli/defaults.yaml` — new; top key `antigravity`, `enabled: false`, version/manifest/dir/completion keys.
- `google/antigravity/cli/map.jinja` — new; merges defaults with pillar `google:antigravity:cli`.
- `google/antigravity/cli/init.sls` — new; routes install/teardown on `enabled`.
- `google/antigravity/cli/install.sls` — new; apply-time manifest lookup, sha512 verify, extract, symlink, guarded completion.
- `google/antigravity/cli/teardown.sls` — new; `file.absent` for completion, symlink, install dir.
- `pillar.sls.example` — adds `antigravity: cli: enabled: false` under `google:`.
- `top.sls` — registers `google.antigravity.cli`.

Full diff: `git show 7962819f8c87b322127b06ef526082f06ddfe3a2`

</details>
