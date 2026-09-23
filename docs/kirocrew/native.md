# KiroCrew — Native mode

Native mode runs KiroCrew directly on the host from the installed package, with
no container or virtual machine between the agent and the workstation. It offers
the least isolation and the most direct access to the host, and is the simplest
mode to operate.

For an overview of all three modes see the
[KiroCrew service README](https://github.com/fjudith/salt-ubuntu-devops-tools/blob/main/kiro/crew/README.md).
This page covers the full
lifecycle of the `native` mode specifically.

## When to use it

- You want KiroCrew to run with direct host access (no container boundary).
- You do not need the isolation of `docker` or `kata` mode.
- The workstation is trusted and single-user.

Native mode has **no isolation**: the agent runs as a host user with that
user's permissions. Prefer [docker](docker.md) or [kata](kata.md) mode when you
want a boundary between the agent and the host.

## Pillar

```yaml
kiro:
  crew:
    enabled: true
    service:
      enabled: true
      mode: native
      # The non-root user KiroCrew runs as. REQUIRED — the state refuses to run
      # as root or with an empty user.
      user: your-user
      bin: kirocrew
```

`service.user` must be a real, non-root user. The state fails early with a
clear message if it is empty or set to `root`.

## Lifecycle

### 1. Install and start

```bash
sudo salt-call --local state.apply kiro.crew
```

This applies, in order:

1. **Package install** — the KiroCrew `.deb`/`.rpm` is installed via
   `pkg.installed` (architecture-aware: `x86_64` or `aarch64`).
2. **Service install** — `kirocrew service install` is run **as
   `service.user`** (not root), which registers the `kirocrew.service` systemd
   unit. This is guarded by `unless: systemctl is-enabled --quiet
   kirocrew.service`, so it is idempotent.
3. **Service start** — `kirocrew.service` is enabled and started.

Applying `kiro.crew` in native mode also tears down any previous `docker` and
`kata` mode artifacts, so switching *to* native cleans up the others.

### 2. Operate

```bash
systemctl status kirocrew.service
journalctl -u kirocrew.service -f
sudo systemctl restart kirocrew.service
```

Because the service was registered by `kirocrew service install`, the KiroCrew
binary owns the unit definition. Manage runtime state with the usual
`systemctl` verbs.

### 3. Upgrade

Native mode follows the package version in pillar
(`kiro:crew:version`, default tracks the latest release). To upgrade:

```yaml
kiro:
  crew:
    version: 0.7.0
```

```bash
sudo salt-call --local state.apply kiro.crew
```

`pkg.installed` installs the pinned version; the service picks it up on the
next restart.

### 4. Teardown

Disable the service (or the whole tool) in pillar and re-apply:

```yaml
kiro:
  crew:
    service:
      enabled: false
```

```bash
sudo salt-call --local state.apply kiro.crew
```

Teardown runs `kirocrew service uninstall` as `service.user` (guarded by
`onlyif: systemctl is-enabled --quiet kirocrew.service`), then removes the
`kirocrew` package. Setting `kiro:crew:enabled: false` removes the package as
well.

## Comparison to container modes

| Aspect | `native` | `docker` / `kata` |
|--------|----------|-------------------|
| Isolation | none (host process) | container / VM |
| Unit ownership | `kirocrew service install` | Salt-managed systemd unit |
| Login | host `kiro-cli login` | interactive helper script |
| Dashboard | served directly by the host process | published on `host_ip:port` |
| Teardown | `kirocrew service uninstall` + `pkg.removed` | `service.dead` + container/image cleanup |

If you need a boundary between the agent and the workstation, use
[docker mode](docker.md) (container isolation) or [kata mode](kata.md)
(hardware VM isolation).
