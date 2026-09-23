# KiroCrew — Docker mode

Docker mode runs the KiroCrew OCI image as a long-running container managed by a
systemd unit (`kirocrew-docker.service`). It gives KiroCrew container-level
isolation from the host while keeping host-backed networking, which makes it the
most reliable mode on **WSL2**.

For an overview of all three modes see the
[KiroCrew service README](https://github.com/fjudith/salt-ubuntu-devops-tools/blob/main/kiro/crew/README.md).
This page covers the full
lifecycle of the `docker` mode specifically.

## When to use it

- You want a boundary between the agent and the host, without the overhead or
  networking constraints of a micro-VM.
- You are on WSL2, where [kata mode has no in-guest
  networking](kata.md#networking-on-wsl2).
- You need the container to have working outbound networking at runtime.

## Requirements

- The `docker` formula (Docker Engine + containerd).
- No Kata or nerdctl dependency — docker mode uses `docker` directly.

## Pillar

```yaml
kiro:
  crew:
    enabled: true
    service:
      enabled: true
      mode: docker
      docker:
        image: ghcr.io/kirodotdev/kirocrew:stable
        container: kirocrew
        volume: kirocrew-home
        # Dashboard published on host_ip:port -> container 5476.
        port: 5476
        host_ip: 127.0.0.1
        service: kirocrew-docker
        # Host directories bind-mounted into the container. Each entry is a
        # dict of source/target, with an optional read_only flag. Read-write
        # sources are created on the host and chowned to uid/gid. See Mounts.
        mounts:
          - source: /home/you/git
            target: /workspace
          - source: /home/you/.aws
            target: /home/kirocrew/.aws
            read_only: true
        # Run in the host user namespace (see userns note below).
        userns_host: true
        uid: 1000
        gid: 1000
        # CPU / memory bounds — see Resources.
        resources:
          cpu:
            max: 4
            min: null
          memory:
            max: 4g
            min: 2g
```

## Lifecycle

### 1. Apply

```bash
sudo salt-call --local state.apply kiro.crew
```

This applies, in order:

1. **Seccomp profile** — downloads the KiroCrew seccomp profile to
   `service.docker.seccomp_profile`.
2. **Image pull** — `docker pull` of the configured image.
3. **Home volume** — `docker volume create` for the persistent home
   (`/home/kirocrew` inside the container), created only if absent.
4. **Home ownership** — when `userns_host` is true, the volume is chowned to
   `uid:gid` on the host so the container user can write it.
5. **Mount sources** — each read-write entry in `mounts` has its `source`
   directory created on the host (chowned to `uid:gid` when `userns_host` is
   true). Read-only sources are left as-is. See [Mounts](#mounts).
6. **Helper scripts** — `kirocrew-docker-login` and `kirocrew-docker-token` are
   dropped on `PATH`.
7. **systemd unit** — `/etc/systemd/system/kirocrew-docker.service` is written
   (`Type=simple`, `Restart=always`) and the service is enabled and started.

Applying docker mode also tears down any `native` and `kata` mode artifacts.

### 2. First-time login

KiroCrew needs an authenticated `kiro-cli` session, and that flow is
interactive, so it cannot run during `state.apply`. Run the helper once:

```bash
sudo kirocrew-docker-login
```

The helper:

1. Stops `kirocrew-docker.service` so the login container can use the home
   volume exclusively.
2. Runs an interactive container that mounts the **same** `kirocrew-home`
   volume the service uses, with a userns policy matching the service so file
   ownership agrees.
3. Uses the device-code flow (`kiro-cli login --use-device-flow`): it prints a
   verification URL and code. Open the URL in a browser on your host, enter the
   code, and approve.
4. Restarts the service.

Credentials land in the `kirocrew-home` volume, so they persist across
container restarts. You only repeat this when the credentials expire.

### 3. Dashboard token

The dashboard requires an access token in the URL. Mint one from the running
container:

```bash
sudo kirocrew-docker-token [TTL]
```

`TTL` is optional (default `2h`, e.g. `30m`, `8h`). The helper runs
`kirocrew token` inside the container and rewrites the printed URL to the
published `host_ip:port`, so the link works from a browser on the host and,
on WSL2, from Windows via localhost forwarding.

### 4. Operate

```bash
systemctl status kirocrew-docker.service
journalctl -u kirocrew-docker.service -f
sudo systemctl restart kirocrew-docker.service
```

The container runs in the foreground under the unit (`Type=simple`), so its
lifecycle follows the service: `systemctl start/stop/restart` work as expected,
a stale container is force-removed on start, and the container is removed on
stop.

### 5. Teardown

Disable the service in pillar and re-apply:

```yaml
kiro:
  crew:
    service:
      enabled: false
```

```bash
sudo salt-call --local state.apply kiro.crew
```

Teardown stops and disables `kirocrew-docker.service`, force-removes the
container, and removes the systemd unit, the helper scripts, and the seccomp
profile. (The `kirocrew-home` volume is left in place so credentials and state
survive a re-enable.)

## Resources (CPU / memory)

Each value under `service.docker.resources` maps to a `docker run` flag; a
`null` value omits its flag.

| Config       | Runtime flag           | Meaning                                      |
|--------------|------------------------|----------------------------------------------|
| `cpu.max`    | `--cpus`               | Hard CPU ceiling, in cores.                  |
| `cpu.min`    | `--cpu-shares`         | Relative CPU weight under contention (soft). |
| `memory.max` | `--memory`             | Hard memory limit.                           |
| `memory.min` | `--memory-reservation` | Soft memory reservation / floor.             |

KiroCrew agent sessions can exhaust small limits, so keep `memory.max` at or
above `4g`. In docker mode these are cgroup limits on a host-kernel container
(unlike kata mode, where they size a micro-VM).

## Mounts

`service.docker.mounts` is a list of host directories bind-mounted into the
container. Each entry is a dict:

| Key         | Required | Meaning                                                       |
|-------------|----------|---------------------------------------------------------------|
| `source`    | yes      | Host path. Read-write sources are created on the host and, when `userns_host` is true, chowned to `uid:gid`. |
| `target`    | yes      | Path inside the container. Must **not** be `/home/kirocrew` (the home volume). |
| `read_only` | no       | Default `false`. When `true`, the mount is added with `:ro` and the source is not created or chowned. |

```yaml
mounts:
  # Workspace: read-write so the agent can create and edit files.
  - source: /home/you/git
    target: /workspace
  # AWS credentials: read-only so the agent can use your profiles.
  - source: /home/you/.aws
    target: /home/kirocrew/.aws
    read_only: true
```

> **Security:** the KiroCrew entrypoint deliberately masks credential paths
> like `~/.aws` and `~/.ssh` by default. Adding a mount for `~/.aws` overrides
> that and hands your AWS credentials to the agent. Mount it `read_only: true`
> so the agent can use, but not modify, your credentials.

The default `mounts` is empty, so no host directories are shared unless you
configure them in pillar.

## userns-remap note

`userns_host: true` runs the container in the host user namespace, so its
`uid`/`gid` map directly to the same ids on the host. This is required for
read/write access to host bind-mounts (the read-write entries in `mounts`) when
the Docker daemon uses userns-remap. Set it to `false` to keep userns-remap
isolation, in
which case host bind-mounts become read-only to the remapped uid. The login
helper mirrors this setting so the login and the service agree on file
ownership.
