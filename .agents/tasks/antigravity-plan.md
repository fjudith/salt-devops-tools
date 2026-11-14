# Implementation Plan — Google Antigravity CLI (`agy`) Salt module

Goal: add a new masterless Salt formula module for the Google Antigravity CLI under
`/srv/salt/google/antigravity/cli/` (vendor `google`, sibling of the existing
`google/cloud/cli/`), plus two edits to existing files (`top.sls`,
`pillar.sls.example`). The module mirrors `oh-my-pi/cli/` (versioned install dir +
symlink + bash completion + checksum verification) and `crossplane/cli/install.sls`
(versioned-dir + `unless`/`creates` guard pattern).

## Design decisions (grounded in the codebase + live facts)

- **Download at apply time, not render time.** The Antigravity GCS URL contains an
  opaque build-id suffix (e.g. `1.3.5-6164039479459840`) and the sha512 is only in a
  per-platform JSON manifest, so neither can be hardcoded in `file.managed`
  `source`/`source_hash` the way `oh-my-pi/cli/install.sls` does. The download +
  sha512 verify + extract is therefore a single `cmd.run` shell block (manifest fetched
  with `curl`, keys parsed with `grep`/`sed` like the official POSIX installer), guarded
  with `creates:` so re-runs are idempotent. This is the only viable approach that keeps
  the mandatory checksum verification.
- **Tarball member rename.** The distributed tarball's single member is a binary named
  `antigravity`; the user-facing command is `agy`. The install block extracts
  `antigravity` and installs it as `agy`.
- **Completion unverified → `completion: false` + best-effort guard.** Web research
  (official cheatsheets, the GitHub repo) shows `agy` subcommands like `agy agents` but
  **no** `agy completion`/`agy completions` subcommand. Per the task's instruction not to
  invent a completion command that may fail the highstate, `defaults.yaml` ships
  `completion: false` with a comment explaining it is unverified, and the `install.sls`
  completion state (rendered only when `completion` is true) is guarded with `onlyif`
  that first probes whether `agy completion` exists, so even if a user flips the flag the
  highstate will not fail.
- **Arch + musl detection** follows the task spec and the official installer: `cpuarch`
  grain → `linux_amd64`/`linux_arm64`, with `_musl` appended when
  `/lib/libc.musl-<arch>.so.1` exists.

## Files to create

### 1. `/srv/salt/google/antigravity/cli/defaults.yaml`  (header `ft=yaml`)

Top-level key `antigravity`. Exact contents:

```yaml
# -*- coding: utf-8 -*-
# vim: ft=yaml
antigravity:
  enabled: false
  # Antigravity CLI version (see https://antigravity.google/docs/cli/overview)
  version: 1.3.5
  manifest_base_url: https://antigravity-cli-auto-updater-974169037036.us-central1.run.app
  install_dir: /usr/local/antigravity
  bin_dir: /usr/local/bin
  # Shell completion: no `agy completion` subcommand is documented upstream, so this
  # is unverified and disabled by default. If enabled, the completion state is
  # best-effort (guarded with onlyif) and will not fail the highstate.
  completion: false
```

Note: the `version` line uses a plain comment (NOT a `# renovate: datasource=...` line),
because Antigravity is not published on GitHub releases.

- Files: `/srv/salt/google/antigravity/cli/defaults.yaml`
- Verify: `salt-call --local state.show_sls google.antigravity.cli -l info` renders
  without YAML errors (full verify in step 8). Structural check: top key is `antigravity`
  and matches the jinja var name in `map.jinja`.

### 2. `/srv/salt/google/antigravity/cli/map.jinja`

Mirror `oh-my-pi/cli/map.jinja`. Merged variable name is `antigravity`; pillar path is
`google:antigravity:cli`. Exact contents:

```jinja
# -*- coding: utf-8 -*-
# vim: ft=jinja

{#- Start imports #}
{% import_yaml tpldir ~ "/defaults.yaml" or {} as defaults %}

{#- Merge in salt pillar #}
{% set antigravity = salt['pillar.get']('google:antigravity:cli', default=defaults['antigravity'], merge=True) %}
```

- Files: `/srv/salt/google/antigravity/cli/map.jinja`
- Verify: structural — `defaults['antigravity']` key matches `defaults.yaml`; pillar path
  `google:antigravity:cli` matches the `top.sls` entry and the `pillar.sls.example` block.
  Rendered in step 8.

### 3. `/srv/salt/google/antigravity/cli/init.sls`

Mirror `oh-my-pi/cli/init.sls`. Exact contents:

```jinja
# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import antigravity with context %}

include:
  {%- if antigravity.enabled %}
  - .install
  {%- elif not antigravity.enabled %}
  - .teardown
  {% endif %}
```

- Files: `/srv/salt/google/antigravity/cli/init.sls`
- Verify: step 8 render; with `enabled: false` (default) `state.show_sls` should resolve
  the `.teardown` include.

### 4. `/srv/salt/google/antigravity/cli/install.sls`

Core logic. Arch/musl detection at render time; download+verify+extract as a single
`cmd.run` guarded with `creates`; versioned install dir via `file.directory`; symlink via
`file.symlink`; optional best-effort completion. Exact contents:

```jinja
# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import antigravity with context %}

{#- Detect architecture -> platform string used in the manifest path #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch in ('x86_64', 'amd64') %}
  {% set platform = 'linux_amd64' %}
  {% set musl_lib = '/lib/libc.musl-x86_64.so.1' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set platform = 'linux_arm64' %}
  {% set musl_lib = '/lib/libc.musl-aarch64.so.1' %}
{% endif %}

{#- musl builds: append _musl, matching the official installer #}
{% if salt['file.file_exists'](musl_lib) %}
  {% set platform = platform ~ '_musl' %}
{% endif %}

{% set manifest_url = antigravity.manifest_base_url ~ '/manifests/' ~ platform ~ '.json' %}
{% set agy_bin = antigravity.install_dir ~ '/' ~ antigravity.version ~ '/agy' %}

antigravity-install-dir:
  file.directory:
    - name: {{ antigravity.install_dir }}/{{ antigravity.version }}
    - user: root
    - group: root
    - mode: '0755'
    - makedirs: true

antigravity-download:
  cmd.run:
    - name: |
        set -e
        TMPDIR="$(mktemp -d)"
        trap 'rm -rf "$TMPDIR"' EXIT
        MANIFEST="$(curl -fsSL '{{ manifest_url }}')"
        # POSIX JSON key parse (mirrors the official installer's parse_json_key)
        URL="$(printf '%s' "$MANIFEST" | grep -o '"url"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:[[:space:]]*"//;s/"$//')"
        SHA="$(printf '%s' "$MANIFEST" | grep -o '"sha512"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:[[:space:]]*"//;s/"$//')"
        if [ -z "$URL" ] || [ -z "$SHA" ]; then echo "failed to parse manifest {{ manifest_url }}" >&2; exit 1; fi
        curl -fsSL "$URL" -o "$TMPDIR/cli.tar.gz"
        # Security check: FAIL on sha512 mismatch, never skip verification
        echo "$SHA  $TMPDIR/cli.tar.gz" | sha512sum -c -
        tar -xzf "$TMPDIR/cli.tar.gz" -C "$TMPDIR"
        install -o root -g root -m 0755 "$TMPDIR/antigravity" '{{ agy_bin }}'
    - creates: {{ agy_bin }}
    - require:
      - file: antigravity-install-dir

antigravity-symlink:
  file.symlink:
    - name: {{ antigravity.bin_dir }}/agy
    - target: {{ agy_bin }}
    - force: true
    - require:
      - cmd: antigravity-download

{%- if antigravity.completion %}
antigravity-completion:
  cmd.run:
    - name: {{ antigravity.bin_dir }}/agy completion bash | tee /etc/bash_completion.d/agy
    - creates: /etc/bash_completion.d/agy
    # best-effort: only run if `agy completion` actually exists (unverified upstream)
    - onlyif: {{ antigravity.bin_dir }}/agy completion bash >/dev/null 2>&1
    - require:
      - file: antigravity-symlink
{%- endif %}
```

Notes for the implementer:
- The tarball member is `antigravity`; if a future tarball nests it under a subdir,
  adjust the `install` source path — verify by listing `tar -tzf` output during the
  live apply test (step 8, optional).
- `creates: {{ agy_bin }}` makes the whole download block idempotent (re-runs skip it),
  mirroring crossplane's `unless`/oh-my-pi's `test -f` guards.
- Do NOT add `skip_verify`/`--insecure`; sha512 verification is mandatory.

- Files: `/srv/salt/google/antigravity/cli/install.sls`
- Verify: step 8 render (`state.show_sls`) catches Jinja/YAML errors. Optional live
  apply with `enabled: true` confirms manifest parse + sha512 + extract + symlink.

### 5. `/srv/salt/google/antigravity/cli/teardown.sls`

Mirror `oh-my-pi/cli/teardown.sls`. Exact contents:

```jinja
# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import antigravity with context %}

antigravity-teardown-completion:
  file.absent:
    - name: /etc/bash_completion.d/agy

antigravity-teardown-symlink:
  file.absent:
    - name: {{ antigravity.bin_dir }}/agy

antigravity-teardown-install-dir:
  file.absent:
    - name: {{ antigravity.install_dir }}
```

- Files: `/srv/salt/google/antigravity/cli/teardown.sls`
- Verify: step 8 render; with default `enabled: false`, `state.show_sls` resolves these
  three `file.absent` states.

## Edits to existing files

### 6. `/srv/salt/top.sls`

Add `    - google.antigravity.cli` to the `base: "*":` list, near the other agent tooling
(after `oh-my-pi.cli`, before `vllm`). Note `google.cloud.cli` is already present earlier;
`google.cloud.cli` itself is unrelated to this change.

Edit (anchor on the tail of the list):

```yaml
    - agno.agentos
    - oh-my-pi.cli
    - google.antigravity.cli
    - vllm
```

- Files: `/srv/salt/top.sls`
- Verify: step 8 — the entry resolves to `/srv/salt/google/antigravity/cli/init.sls`
  (Salt maps `google.antigravity.cli` → that path). Valid YAML list indentation (4 spaces).

### 7. `/srv/salt/pillar.sls.example`

Under the existing top-level `google:` key, add an `antigravity: cli: enabled: false`
block so it reads exactly:

```yaml
google:
  cloud:
    cli:
      enabled: false
  antigravity:
    cli:
      enabled: false
```

- Files: `/srv/salt/pillar.sls.example`
- Verify: valid YAML; the nested path `google:antigravity:cli` matches the
  `salt['pillar.get']('google:antigravity:cli', ...)` in `map.jinja` (step 2).

## Consistency requirement (must hold across all files)

- Module directory: `google/antigravity/cli/`
- Pillar path:      `google:antigravity:cli`  (map.jinja + pillar.sls.example)
- top.sls entry:    `google.antigravity.cli`
- defaults.yaml top key AND merged jinja var: `antigravity`

Salt resolves the state path from the top-file entry, so these four must agree exactly.

## 8. Final verification

Primary (preferred) — render the states to catch Jinja/YAML errors:

```bash
sudo salt-call --local state.show_sls google.antigravity.cli -l info
```

Expected: renders without a `Rendering SLS ... failed` / Jinja traceback. With the
default `enabled: false`, the output contains the three `antigravity-teardown-*`
`file.absent` states (from `.teardown`). Flip the pillar to `enabled: true` (or temporarily
`defaults.yaml`) and re-run to confirm `.install` renders the `antigravity-install-dir`,
`antigravity-download`, and `antigravity-symlink` states.

Optional dry run / live apply:

```bash
sudo salt-call --local state.apply google.antigravity.cli test=True
# live (with google:antigravity:cli:enabled: true in pillar):
sudo salt-call --local state.apply google.antigravity.cli
agy --version   # confirms the symlinked binary runs
```

Fallback if `salt-call` is unavailable — re-read each file and confirm by inspection:
- `map.jinja` pillar path `google:antigravity:cli` == `pillar.sls.example` nesting and
  `defaults['antigravity']` key == `defaults.yaml` top key.
- `init.sls` routes `.install` when enabled else `.teardown`.
- `top.sls` edit is a valid 4-space-indented list item.
- `pillar.sls.example` `google:` block is valid YAML with the new `antigravity` branch.
- Every `.sls`/`.jinja` file starts with `# -*- coding: utf-8 -*-` + `# vim: ft=jinja`,
  and `defaults.yaml` with `# vim: ft=yaml`.

## Known gaps / assumptions

- **Completion command is unverified.** No `agy completion` subcommand is documented
  upstream; defaults ship `completion: false` and the completion state is `onlyif`-guarded
  so it cannot fail the highstate. If upstream later documents a real command, update the
  `name`/`onlyif` in `install.sls` accordingly.
- **Tarball layout assumed flat** (single member `antigravity` at the archive root). If
  the live `tar -tzf` shows a nested path, the implementer must adjust the `install`
  source path in `antigravity-download`.
