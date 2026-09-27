# KiroCrew

Provisions the [KiroCrew](https://github.com/kirodotdev/KiroCrew) agent as a
long-running service on an Ubuntu/Linux workstation. The `kiro.crew` state
installs the KiroCrew package and, when the service is enabled, runs it in one
of three modes — `native` on the host, `docker` in a container, or `kata`
inside a hardware-isolated micro-VM.

## TL;DR

```yaml
# /srv/pillar/devops.sls
kiro:
  crew:
    enabled: true
    service:
      enabled: true
      mode: kata          # native | docker | kata
```

```bash
sudo salt-call --local state.apply kiro.crew
sudo kirocrew-kata-login    # once, interactive
sudo kirocrew-kata-token    # prints a dashboard URL
```

## Introduction

This formula bootstraps a KiroCrew deployment on a workstation using
[SaltStack](https://saltproject.io/) in masterless mode (`salt-call --local`).
It installs the pinned KiroCrew release and, optionally, wires it up as a
systemd-managed service. Three delivery modes trade off isolation against
setup cost:

| Mode     | How KiroCrew runs                                              | Isolation     |
|----------|----------------------------------------------------------------|---------------|
| `native` | Installed binary managed via `kirocrew service install`        | none (host)   |
| `docker` | Docker container managed by a systemd unit (`kirocrew-docker`) | container     |
| `kata`   | OCI image inside a Kata Containers micro-VM (Cloud Hypervisor) | hardware (VM) |

Only one mode is active at a time. Switching modes automatically tears down the
others on the next `state.apply`. Both container modes run the container in the
foreground under a `Type=simple` systemd unit (`Restart=always`), so the
container lifecycle follows the service and the dashboard is published on
`host_ip:port` (default `127.0.0.1:5476`).

## Prerequisites

- Ubuntu (Debian family) or RedHat family host, x86_64 or aarch64
- SaltStack (`salt-call`) configured for masterless use
- For `docker` mode: the `docker` formula enabled
- For `kata` mode: the `kata-containers.kata-containers` state, containerd (via
  the `docker` formula), and KVM (`/dev/kvm`) on the host

## Installing the formula

Enable the service in pillar and pick a mode, then apply the state. `docker`
mode runs under the Docker daemon, so the `docker` formula must be enabled too
— its systemd unit is ordered `After=docker.service` / `Requires=docker.service`
and shells out to the `docker` CLI:

```yaml
# docker mode depends on the docker formula (daemon + CLI)
docker:
  enabled: true

kiro:
  crew:
    enabled: true
    service:
      enabled: true
      mode: docker
```

```bash
sudo salt-call --local state.apply kiro.crew
```

The command installs the pinned KiroCrew package, provisions the systemd unit
and helpers for the selected mode, and tears down any other mode.

## Uninstalling the formula

Disable the service (or the whole component) in pillar and re-apply:

```yaml
kiro:
  crew:
    service:
      enabled: false
```

```bash
sudo salt-call --local state.apply kiro.crew
```

This stops and removes the systemd unit and container for the active mode. Set
`kiro:crew:enabled: false` to also remove the installed package.

## Parameters

### Common parameters

| Name       | Description                                            | Value                                                     |
|------------|--------------------------------------------------------|-----------------------------------------------------------|
| `enabled`  | Install the KiroCrew package                           | `true`                                                    |
| `version`  | KiroCrew release to install (pinned)                   | `0.7.1`                                                   |
| `base_url` | Base URL for release artifact downloads                | `https://github.com/kirodotdev/KiroCrew/releases/download`|

### Service parameters

| Name              | Description                                                  | Value       |
|-------------------|--------------------------------------------------------------|-------------|
| `service.enabled` | Run KiroCrew as a long-running service                       | `false`     |
| `service.mode`    | Delivery mode: `native`, `docker`, or `kata`                 | `native`    |
| `service.user`    | User the native service runs as (`null` = install default)   | `null`      |
| `service.bin`     | Name of the KiroCrew binary on PATH                          | `kirocrew`  |

### Docker mode parameters

| Name                                       | Description                                                          | Value                                    |
|--------------------------------------------|----------------------------------------------------------------------|------------------------------------------|
| `service.docker.image`                     | Container image (tag tracks `version`)                               | `ghcr.io/kirodotdev/kirocrew:0.7.1`      |
| `service.docker.container`                 | Container name                                                       | `kirocrew`                               |
| `service.docker.volume`                    | Named volume for the persistent container home                       | `kirocrew-home`                          |
| `service.docker.port`                      | Dashboard port inside the container                                  | `5476`                                   |
| `service.docker.host_ip`                   | Host address the dashboard is published on                           | `127.0.0.1`                              |
| `service.docker.service`                   | systemd unit that manages the container lifecycle                    | `kirocrew-docker`                        |
| `service.docker.resources.cpu.max`         | Hard CPU ceiling in cores (`--cpus`); `null` = unbounded             | `null`                                   |
| `service.docker.resources.cpu.min`         | Relative CPU weight under contention (`--cpu-shares`)                | `null`                                   |
| `service.docker.resources.memory.max`      | Hard memory limit (`--memory`); keep >= `4g`                         | `4g`                                     |
| `service.docker.resources.memory.min`      | Soft memory reservation (`--memory-reservation`)                     | `null`                                   |
| `service.docker.token_ttl`                 | Default TTL for dashboard tokens                                     | `2h`                                     |
| `service.docker.mounts`                    | Host directories bind-mounted into the container (list of dicts)     | `[]`                                     |
| `service.docker.userns_host`               | Run in the host user namespace (needed for RW host bind-mounts)      | `true`                                   |
| `service.docker.uid`                       | UID the container user maps to                                       | `1000`                                   |
| `service.docker.gid`                       | GID the container user maps to                                       | `1000`                                   |
| `service.docker.seccomp_profile`           | Path to the seccomp profile applied to the container                 | `/etc/kirocrew/kirocrew-seccomp.json`    |
| `service.docker.seccomp_url`               | Source URL for the seccomp profile                                   | KiroCrew repo `kirocrew-seccomp.json`    |

### Kata mode parameters

| Name                                    | Description                                                        | Value                                   |
|-----------------------------------------|--------------------------------------------------------------------|-----------------------------------------|
| `service.kata.image`                    | Container image run inside the micro-VM                            | `ghcr.io/kirodotdev/kirocrew:stable`    |
| `service.kata.container`                | Container name                                                     | `kirocrew`                              |
| `service.kata.port`                     | Dashboard port inside the container                               | `5476`                                  |
| `service.kata.host_ip`                  | Host address the dashboard is published on                        | `127.0.0.1`                             |
| `service.kata.runtime`                  | containerd runtime handler (Cloud Hypervisor backend)             | `io.containerd.kata-clh.v2`             |
| `service.kata.namespace`                | containerd namespace the service runs in                          | `kirocrew`                              |
| `service.kata.service`                  | systemd unit that manages the container lifecycle                 | `kirocrew-kata`                         |
| `service.kata.resources.cpu.max`        | Hard CPU ceiling in cores (`--cpus`); also sizes VM vCPUs         | `null`                                  |
| `service.kata.resources.cpu.min`        | Relative CPU weight under contention (`--cpu-shares`)             | `null`                                  |
| `service.kata.resources.memory.max`     | Hard memory limit (`--memory`); sizes guest RAM; keep >= `4g`     | `4g`                                    |
| `service.kata.resources.memory.min`     | Soft memory reservation (`--memory-reservation`)                  | `null`                                  |
| `service.kata.token_ttl`                | Default TTL for dashboard tokens                                  | `2h`                                    |
| `service.kata.network`                  | Dedicated CNI network for the container                           | `kirocrew`                              |
| `service.kata.subnet`                   | CNI subnet                                                        | `10.88.0.0/24`                          |
| `service.kata.container_ip`             | Fixed container IP for the host-side socket proxy                 | `10.88.0.10`                            |
| `service.kata.proxy_service`            | systemd socket-proxy unit forwarding host_ip:port to the VM       | `kirocrew-kata-proxy`                   |
| `service.kata.mounts`                   | Host directories shared into the guest (list of dicts)            | `[{source: /var/lib/kirocrew/shared, target: /workspace}]` |
| `service.kata.home_dir`                 | Persistent home on the host (KiroCrew state + login creds)        | `/var/lib/kirocrew/home`                |
| `service.kata.home_mount`               | Guest path the home is bind-mounted to                            | `/home/kirocrew`                        |
| `service.kata.home_uid`                 | UID the container `kirocrew` user runs as                         | `1000`                                  |
| `service.kata.home_gid`                 | GID the container `kirocrew` user runs as                         | `1000`                                  |

> **Security:** the KiroCrew entrypoint deliberately masks `~/.aws` by default.
> Adding a read-write `.aws` mount hands your AWS credentials to the agent. Use
> `read_only: true` for any credential mount, and note that `mounts` targets
> must not shadow the container home (`/home/kirocrew`).

## Configuration and installation details

### Resource limits

Both container modes expose CPU and memory bounds under
`service.<mode>.resources`. Each value maps to a `docker run` / `nerdctl run`
flag; any value left `null` omits its flag, leaving that dimension unbounded.

```yaml
kiro:
  crew:
    service:
      kata:            # or: docker
        resources:
          cpu:
            max: 8     # up to 8 cores
            min: null  # no hard CPU floor (see below)
          memory:
            max: 16g   # hard limit
            min: 8g    # soft reservation
```

Two things to keep in mind:

- **Kata sizes the micro-VM from these values.** With the `clh` backend,
  `cpu.max` becomes the guest vCPU count and `memory.max` becomes the guest
  RAM, so the host must have that much CPU and free RAM or the VM will not
  boot. In `docker` mode they are cgroup limits on a host-kernel container.
- **`*.min` is soft, not a guarantee.** `--cpu-shares` is only a relative
  weight the scheduler honors under contention, and `--memory-reservation` is
  enforced only under host memory pressure. Neither preallocates capacity, and
  there is no runtime flag for a hard "minimum cores".

Defaults set `memory.max: 4g` and leave the rest `null`. KiroCrew agent
sessions (managed CPython, `kiro-cli`, MCP tools, in-process embeddings) can
exhaust small limits, so keep `memory.max` at or above `4g`.

### First-time login

KiroCrew needs an authenticated `kiro-cli` session. That flow is interactive,
so it cannot run during `state.apply`. Each container mode ships a helper on
PATH that runs the login once against the same home the service uses, so the
credentials persist across restarts (and, for `kata`, across VM reboots):

| Mode     | Helper                       | Credentials land in            |
|----------|------------------------------|--------------------------------|
| `docker` | `sudo kirocrew-docker-login` | `kirocrew-home` named volume   |
| `kata`   | `sudo kirocrew-kata-login`   | `home_dir` on the host         |

Each helper stops the service, runs the login, then restarts the service.
Because the container has no browser, it uses `kiro-cli login
--use-device-flow`: it prints a verification URL and code. Open the URL in a
browser on your host, enter the code, and approve. You only repeat this when
the credentials expire.

> In `kata` mode the login container runs under **Docker**, not Kata.
> `kiro-cli login` needs working outbound networking, and credentials are
> runtime-agnostic files in the persistent home, so it does not matter which
> runtime writes them. This also sidesteps the Kata-on-WSL2 networking
> limitation described below.

### Dashboard token

The dashboard requires an access token in the URL (`?token=...`). Each
container mode ships a helper that mints one from the running container and
prints a ready-to-open URL:

- `docker` mode: `sudo kirocrew-docker-token [TTL]`
- `kata` mode: `sudo kirocrew-kata-token [TTL]`

`TTL` is optional (default `2h`, e.g. `30m`, `8h`). The printed URL uses the
host address the dashboard is published on (`host_ip:port`), so it works from a
browser on the host and, on WSL2, from Windows via localhost forwarding.

### Status and logs

```bash
systemctl status kirocrew-kata.service      # or kirocrew-docker.service
journalctl -u kirocrew-kata.service -f
```

### Kata mode

`kata` mode runs the KiroCrew OCI image inside a lightweight virtual machine
using [Kata Containers](https://katacontainers.io/) with the Cloud Hypervisor
(`clh`) backend. containerd handles the image; Kata boots a micro-VM per
container and shares directories into the guest over virtio-fs.

Requirements:

- The `kata-containers.kata-containers` state must be enabled (installs Kata
  under `/opt/kata` and registers the `kata-clh` containerd runtime).
- KVM must be available on the host (`/dev/kvm`). Nested virtualization is
  required if the host is itself a VM.
- containerd (installed via the `docker` formula).

Example pillar. `kata` mode's `init.sls` automatically includes the
`kata-containers.kata-containers` and `containerd.nerdctl` states, but each
still needs `enabled: true` in pillar to install anything, and `nerdctl` /
containerd come from the `docker` formula — so enable all three dependencies:

```yaml
# kata mode depends on these states (pulled in by kiro.crew, but enable them):
docker:
  enabled: true               # provides containerd

containerd:
  nerdctl:
    enabled: true             # runs the image with a dedicated CNI network

kata-containers:
  kata-containers:
    enabled: true             # installs Kata + the kata-clh containerd runtime

kiro:
  crew:
    enabled: true
    service:
      enabled: true
      mode: kata
      kata:
        mounts:
          - source: /home/you/git
            target: /workspace
          - source: /home/you/.aws        # read-only credential mount
            target: /home/kirocrew/.aws
            read_only: true
        home_dir: /var/lib/kirocrew/home
        home_mount: /home/kirocrew
        home_uid: 1000
        home_gid: 1000
        resources:
          cpu:
            max: 8
            min: null
          memory:
            max: 16g
            min: 8g
```

The container runs as uid/gid 1000 (`kirocrew`). `home_dir` is created on the
host with that ownership and bind-mounted to `/home/kirocrew` so KiroCrew's
state and credentials persist across restarts and VM reboots.

How it fits together:

```
kirocrew-kata.service (systemd)
  └─ nerdctl run --runtime io.containerd.kata-clh.v2
        --cpus/--memory (size the VM)  --network kirocrew --ip 10.88.0.10
     └─ containerd
          └─ containerd-shim-kata-clh-v2   (KATA_CONF_FILE=configuration-clh.toml)
               └─ cloud-hypervisor          (boots the micro-VM on KVM)
                    ├─ virtiofsd            (shares home_dir + mounts into guest)
                    └─ Kata micro-VM        (guest kernel + kirocrew container :5476)

kirocrew-kata-proxy.socket (systemd, listens on host_ip:port)
  └─ kirocrew-kata-proxy.service
       └─ systemd-socket-proxyd -> 10.88.0.10:5476   (into the container)
```

The service runs the image with `nerdctl` (not `ctr`) so it gets a dedicated
CNI network and a fixed container IP, and `--cpus` / `--memory` from the
resource config size the micro-VM. A CNI portmap publish is DNAT-only and has
no listening socket, so WSL2 does not mirror it to Windows. Instead a systemd
`.socket` opens a real listener on `host_ip:port` and `systemd-socket-proxyd`
forwards to the container IP — which WSL2 does mirror — while Kata VM isolation
is preserved.

### Networking on WSL2

Kata micro-VM networking relies on host kernel features (tc redirect or
macvtap) to plumb a network interface into the guest. On a normal bare-metal or
KVM host this works and the Kata service has outbound networking. On **WSL2**
the kernel does not fully support these paths (the `macvtap` module cannot be
loaded and `tcfilter` redirection does not reach the guest), so a Kata
container boots with no usable network interface.

What that means in practice:

- Login still works, because the helper runs under Docker (see
  [First-time login](#first-time-login)).
- The KiroCrew Kata service itself has no outbound network inside the micro-VM.
  If your workload needs network at runtime, use `mode: docker` on WSL2 and
  reserve `mode: kata` for bare-metal / real-KVM hosts.
