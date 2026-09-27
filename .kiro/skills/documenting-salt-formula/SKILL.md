---
name: documenting-salt-formula
description: Use when documenting a SaltStack formula in the salt-ubuntu-devops-tools repo — writing or updating a formula's README.md in the Helm/Artifact Hub style (TL;DR, Prerequisites, Installing, Parameters tables, Configuration details). Covers deriving docs from defaults.yaml, map.jinja, and init.sls. Triggers on "document a formula", "write a README for <formula>", "add a README", "generate formula docs".
---

# Documenting a Salt formula

Write a formula's `README.md` in the repo's Helm/Artifact Hub documentation
style, derived entirely from the formula's own source files. The gold standard
is `kiro/crew/README.md`.

## When to use this skill

- Adding a `README.md` to a formula under `<vendor>/<tool>/`
- Rewriting an existing formula README into the standard style
- Keeping a README's Parameters table in sync with `defaults.yaml`

## Repo conventions (assumed context)

This repo (`salt-ubuntu-devops-tools`) runs masterless (`salt-call --local`).
Each tool module follows: `defaults.yaml` (defaults + `enabled: false` safe
default) → `map.jinja` (merges defaults with pillar via `salt['pillar.get']`) →
`init.sls` (routes to `.install` / `.teardown` on the `enabled` flag) →
`install.sls` / `teardown.sls` (+ optional `repo.sls`, `config.sls`, `files/`).
Pillar keys mirror the directory structure and each tool has an `enabled`
boolean.

## Procedure (do these in order)

Documentation is **derived, never invented**. Read the source of truth first,
then write.

1. **Read `defaults.yaml`** — this is the parameter table. Every row in the
   Parameters section must trace to a key here, with its literal default.
2. **Read `map.jinja`** — find the `salt['pillar.get']('<path>', ...)` call.
   That `<path>` (e.g. `kiro:crew`, `containerd:nerdctl`) is the formula's
   pillar root. Every parameter name in the table is dotted **relative to this
   root**, and every pillar example nests under it.
3. **Read `init.sls`** — the `include:` block reveals dependency states and any
   mode routing (native/docker/kata style branches). Every included companion
   state is a dependency (see Dependencies rule).
4. **Read `install.sls` / `teardown.sls`** (and `repo.sls`, `config.sls`,
   `files/*.service` if present) — for install method, systemd units, and any
   `Requires=` / `After=` in service files that imply further dependencies.
5. **Pick the tier** (see below) and **write** `<vendor>/<tool>/README.md`
   using `references/readme-template.md` as the skeleton.
6. **Self-check** (see Verification). Do not apply states.

## Pick the tier

Decide by inspecting `defaults.yaml`:

- **Service formula** — has a `service:` block, a systemd unit, a daemon, or
  multiple delivery modes (e.g. native/docker/kata). Use the **full** template:
  Title + intro, TL;DR, Introduction, Prerequisites, Installing, Uninstalling,
  Parameters (grouped), Configuration and installation details.
- **Tool formula** — a single binary/package on PATH, typically just `enabled`
  + `version` (+ URLs). Use the **lean** template: Title + one-line intro,
  TL;DR pillar snippet, Parameters, one usage note.

Mandatory in **both** tiers: a **Parameters** table and a **TL;DR** pillar
example.

## Parameters table (hard format)

Four columns, in this order:

```
| Name | Description | Type | Default |
```

- **Name**: dotted path **relative to the formula's pillar root** from
  `map.jinja` (e.g. `service.docker.image`, not `kiro:crew:service:docker`).
- **Description**: what it does; carry nuance here (units, "keep >= 4g", "null
  omits the flag").
- **Type**: `bool`, `string`, `int`, `list`, `dict` (or `list of dict`).
- **Default**: the literal value from `defaults.yaml`. Render list/dict
  defaults compactly — `[]`, `{}`, or an inline `[{source: ..., target: ...}]`
  — and push the explanation to Description.

Once a formula has nested config, split into **one table per top-level
sub-tree** with a `###` heading each (e.g. Common parameters, Service
parameters, Docker mode parameters, Kata mode parameters), mirroring the
grouping in `kiro/crew/README.md`.

## Dependencies rule (hard)

Companion states are the most common documentation gap — enforce this:

- Parse the `init.sls` `include:` block. Any included state **outside** the
  formula's own subtree (e.g. `docker`, `containerd.nerdctl`,
  `kata-containers.kata-containers`) is a dependency. List it under
  **Prerequisites**.
- Also treat `Requires=` / `After=` targets in `files/*.service` as
  dependencies (e.g. a unit `Requires=docker.service` means the `docker`
  formula).
- **Every runnable pillar example must enable the dependency states too.** An
  included state still needs its own `enabled: true` in pillar to install —
  `init.sls` including it does not enable it. Show them enabled, e.g.:

  ```yaml
  docker:
    enabled: true          # provides the daemon this mode runs under
  containerd:
    nerdctl:
      enabled: true
  ```

## Verification (no execution)

Documentation task — never run `state.apply`, not even `test=True`, since
states apply on the real workstation. Self-check instead:

- Every Parameters row traces to a key in `defaults.yaml`, with matching
  default.
- The pillar root in every example matches the `pillar.get` path in
  `map.jinja`.
- The dependencies listed match the `init.sls` includes and service-file
  `Requires=`.
- All `.sls`/`.md` conventions respected; if `.pre-commit-config.yaml`
  configures a markdown linter, mention running it (don't auto-run host states).

## Repo integration (mention, don't force)

Output is `<vendor>/<tool>/README.md`. If the repo indexes docs (a
`mkdocs.yaml` nav, a `docs/` tree), mention wiring the new README into it, but
only push that step when the formula's docs are clearly meant to be indexed.

## Common gotchas

- Do not copy another formula's numbers. Types and defaults are per-formula;
  always re-read that formula's `defaults.yaml`.
- The pillar path in `map.jinja` is not always the directory path with colons
  (though it usually is) — read it, don't assume.
- A `version:` key often carries a `# renovate:` comment above it; leave that
  comment in the source untouched, and use the pinned version in image
  tags/URLs in the docs.
- `enabled` defaults to `false` in most formulas as a safe default, even when a
  specific one ships `true` — report the actual value.
