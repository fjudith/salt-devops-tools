# README skeletons

Two skeletons. Pick by tier (see SKILL.md). Fill from the formula's
`defaults.yaml` / `map.jinja` / `init.sls`; delete bracketed guidance.

---

## Full template (service formula)

````markdown
# <ToolName>

Installs [<ToolName>](<upstream-url>) — <one-sentence description of what it
provisions on the workstation>.

## TL;DR

```yaml
# /srv/pillar/devops.sls
<pillar-root>:            # matches map.jinja pillar.get path
  enabled: true
  service:
    enabled: true
    mode: <default-mode>   # <list the modes if multiple>
```

```bash
sudo salt-call --local state.apply <state.path>
# <any one-time interactive helper, e.g. login/token>
```

## Introduction

<What it does and how it's delivered. If it has multiple modes, a table:>

| Mode     | How it runs | Isolation |
|----------|-------------|-----------|
| `<mode>` | <...>       | <...>     |

## Prerequisites

- <OS / arch constraints>
- <Dependency states from init.sls includes — list each, e.g. the `docker`
  formula, `containerd.nerdctl`, `kata-containers.kata-containers`>
- <Host requirements from service files, e.g. KVM at /dev/kvm>

## Installing the formula

<Enable in pillar — INCLUDING dependency states — then apply.>

```yaml
<dependency-state>:
  enabled: true            # <why it's needed>

<pillar-root>:
  enabled: true
  service:
    enabled: true
    mode: <mode>
```

```bash
sudo salt-call --local state.apply <state.path>
```

## Uninstalling the formula

```yaml
<pillar-root>:
  service:
    enabled: false
```

```bash
sudo salt-call --local state.apply <state.path>
```

<Note what teardown removes; set enabled: false to remove the package.>

## Parameters

### Common parameters

| Name      | Description        | Type   | Default |
|-----------|--------------------|--------|---------|
| `enabled` | <...>              | bool   | `<...>` |
| `version` | <...>              | string | `<...>` |

### <Sub-tree> parameters

| Name              | Description | Type | Default |
|-------------------|-------------|------|---------|
| `service.<...>`   | <...>       | <..> | `<...>` |

<One table per top-level sub-tree. Names dotted, relative to the pillar root.>

## Configuration and installation details

<Prose sections carried from source: resource limits, first-time login, tokens,
architecture diagram, platform caveats (e.g. WSL2). Only what the source
supports.>
````

---

## Lean template (tool formula)

````markdown
# <ToolName>

Installs [<ToolName>](<upstream-url>) — <one-line description>.

## TL;DR

```yaml
# /srv/pillar/devops.sls
<pillar-root>:
  enabled: true
```

```bash
sudo salt-call --local state.apply <state.path>
```

## Parameters

| Name      | Description | Type   | Default |
|-----------|-------------|--------|---------|
| `enabled` | <...>       | bool   | `<...>` |
| `version` | <...>       | string | `<...>` |
| `<...>`   | <...>       | <...>  | `<...>` |

## Usage

<One note: the binary it drops on PATH, or how to verify, e.g. `<tool> --version`.>
````
