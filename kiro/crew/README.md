# KiroCrew service

Provisions the KiroCrew agent as a long-running service on the workstation.
The `kiro.crew` state installs the KiroCrew package and, when
`kiro:crew:service:enabled` is true, runs it in one of three modes selected by
`kiro:crew:service:mode`.

- [Quick start](#quick-start)
- [Service modes](#service-modes)
- [Resources (CPU / memory)](#resources-cpu--memory)
- [Operating the service](#operating-the-service)
- [Kata mode](#kata-mode)

## Quick start

Enable the service in pillar, pick a mode, then apply:

```yaml
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

For `kata` mode see [its requirements](#requirements) first — it needs KVM and
the `kata-containers` state.

## Service modes

| Mode     | How KiroCrew runs                                              | Isolation     |
|----------|----------------------------------------------------------------|---------------|
| `native` | Installed binary managed via `kirocrew service install`        | none (host)   |
| `docker` | Docker container managed by a systemd unit (`kirocrew-docker`) | container     |
| `kata`   | OCI image inside a Kata Containers micro-VM (Cloud Hypervisor) | hardware (VM) |

Only one mode is active at a time. Switching modes automatically tears down the
others on the next `state.apply`.

Both container modes (`docker` and `kata`) run the container in the foreground
under a systemd unit (`Type=simple` with `Restart=always`), so the container
lifecycle follows the service — `systemctl start/stop/restart` and
`systemctl status` work as expected, and the container is removed on stop. The
dashboard is published on `host_ip:port` (default `127.0.0.1:5476`).

## Resources (CPU / memory)

Both container modes expose CPU and memory bounds under
`service:<mode>:resources`. Each value maps to a `docker run` / `nerdctl run`
flag; any value left `null` omits its flag, leaving that dimension unbounded.

| Config       | Runtime flag           | Meaning                                      |
|--------------|------------------------|----------------------------------------------|
| `cpu.max`    | `--cpus`               | Hard CPU ceiling, in cores.                  |
| `cpu.min`    | `--cpu-shares`         | Relative CPU weight under contention (soft). |
| `memory.max` | `--memory`             | Hard memory limit.                           |
| `memory.min` | `--memory-reservation` | Soft memory reservation / floor.             |

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

Defaults set `memory.max: 4g` and leave the rest `null`. KiroCrew agent
sessions (managed CPython, `kiro-cli`, MCP tools, in-process embeddings) can
exhaust small limits, so keep `memory.max` at or above `4g`.

Two things to keep in mind:

- **Kata sizes the micro-VM from these values.** With the `clh` backend,
  `cpu.max` becomes the guest vCPU count and `memory.max` becomes the guest
  RAM, so the host must have that much CPU and free RAM or the VM will not
  boot. In `docker` mode they are cgroup limits on a host-kernel container
  instead.
- **`*.min` is soft, not a guarantee.** `--cpu-shares` is only a relative
  weight the scheduler honors under contention, and `--memory-reservation` is
  enforced only under host memory pressure. Neither preallocates capacity, and
  there is no runtime flag for a hard "minimum cores".

## Operating the service

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
browser on your host, enter the code, and approve. The credentials are written
and the login container exits. You only repeat this when the credentials
expire.

> In `kata` mode the login container runs under **Docker**, not Kata.
> `kiro-cli login` needs working outbound networking, and credentials are
> runtime-agnostic files in the persistent home, so it does not matter which
> runtime writes them. This also sidesteps the
> [Kata-on-WSL2 networking limitation](#networking-on-wsl2).

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

## Kata mode

`kata` mode runs the KiroCrew OCI image inside a lightweight virtual machine
using [Kata Containers](https://katacontainers.io/) with the Cloud Hypervisor
(`clh`) backend. containerd handles the image; Kata boots a micro-VM per
container and shares directories into the guest over virtio-fs.

### Requirements

- The `kata-containers.kata-containers` state must be enabled (installs Kata
  under `/opt/kata` and registers the `kata-clh` containerd runtime).
- KVM must be available on the host (`/dev/kvm`). Nested virtualization is
  required if the host is itself a VM.
- containerd (installed via the `docker` formula).

### Pillar

```yaml
kata-containers:
  kata-containers:
    enabled: true

kiro:
  crew:
    enabled: true
    service:
      enabled: true
      mode: kata
      kata:
        # Workspace share: host files made available in the guest.
        shared_dir: /home/you/git
        guest_mount: /workspace
        # Persistent container home: KiroCrew state + kiro-cli login creds.
        home_dir: /var/lib/kirocrew/home
        home_mount: /home/kirocrew
        home_uid: 1000
        home_gid: 1000
        # CPU / memory bounds — see Resources above.
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

### How it fits together

```
kirocrew-kata.service (systemd)
  └─ nerdctl run --runtime io.containerd.kata-clh.v2
        --cpus/--memory (size the VM)  --network kirocrew --ip 10.88.0.10
     └─ containerd
          └─ containerd-shim-kata-clh-v2   (KATA_CONF_FILE=configuration-clh.toml)
               └─ cloud-hypervisor          (boots the micro-VM on KVM)
                    ├─ virtiofsd            (shares home_dir + shared_dir into guest)
                    └─ Kata micro-VM        (guest kernel + kirocrew container :5476)

kirocrew-kata-proxy.socket (systemd, listens on host_ip:port)
  └─ kirocrew-kata-proxy.service
       └─ systemd-socket-proxyd -> 10.88.0.10:5476   (into the container)
```

The service runs the image with `nerdctl` (not `ctr`) so it gets a dedicated
CNI network and a fixed container IP, and `--cpus` / `--memory` from the
[Resources](#resources-cpu--memory) config size the micro-VM.

A CNI portmap publish is DNAT-only and has no listening socket, so WSL2 does
not mirror it to Windows. Instead a systemd `.socket` opens a real listener on
`host_ip:port` and `systemd-socket-proxyd` forwards to the container IP — which
WSL2 does mirror — while Kata VM isolation is preserved.

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
