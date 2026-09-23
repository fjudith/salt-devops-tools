# KiroCrew — Kata mode

Kata mode runs the KiroCrew OCI image inside a lightweight virtual machine using
[Kata Containers](https://katacontainers.io/) with the Cloud Hypervisor (`clh`)
backend. It gives KiroCrew **hardware (VM) isolation** from the host: containerd
handles the image, and Kata boots a micro-VM per container, sharing directories
into the guest over virtio-fs.

For an overview of all three modes see the
[KiroCrew service README](https://github.com/fjudith/salt-ubuntu-devops-tools/blob/main/kiro/crew/README.md).
This page covers the full
lifecycle of the `kata` mode specifically.

## When to use it

- You want the strongest isolation between the agent and the host — a real VM
  boundary, not just a container namespace.
- The host is bare-metal or a real KVM host with nested virtualization.

Kata mode is best on bare-metal / real-KVM hosts. On **WSL2** the micro-VM has
no in-guest networking (see [Networking on WSL2](#networking-on-wsl2)); prefer
[docker mode](docker.md) there.

## Requirements

- The `kata-containers.kata-containers` state enabled (installs Kata under
  `/opt/kata` and registers the `kata-clh` containerd runtime).
- The `containerd.nerdctl` state enabled (the service uses `nerdctl` for CNI
  networking and port publishing).
- KVM available on the host (`/dev/kvm`). Nested virtualization is required if
  the host is itself a VM.
- containerd (installed via the `docker` formula).

## Pillar

```yaml
kata-containers:
  kata-containers:
    enabled: true

containerd:
  nerdctl:
    enabled: true

kiro:
  crew:
    enabled: true
    service:
      enabled: true
      mode: kata
      kata:
        image: ghcr.io/kirodotdev/kirocrew:stable
        container: kirocrew
        port: 5476
        host_ip: 127.0.0.1
        runtime: io.containerd.kata-clh.v2
        namespace: kirocrew
        service: kirocrew-kata
        # Dedicated CNI network + fixed container IP.
        network: kirocrew
        subnet: 10.88.0.0/24
        container_ip: 10.88.0.10
        proxy_service: kirocrew-kata-proxy
        # Workspace share: host files made available in the guest.
        shared_dir: /home/you/git
        guest_mount: /workspace
        # Persistent container home: KiroCrew state + kiro-cli login creds.
        home_dir: /var/lib/kirocrew/home
        home_mount: /home/kirocrew
        home_uid: 1000
        home_gid: 1000
        # CPU / memory bounds — these SIZE THE MICRO-VM. See Resources.
        resources:
          cpu:
            max: 8
            min: null
          memory:
            max: 16g
            min: 8g
```

The container runs as uid/gid 1000 (`kirocrew`). `home_dir` is created on the
host with that ownership and bind-mounted to `/home/kirocrew`, so KiroCrew's
state and credentials persist across restarts and VM reboots.

## Lifecycle

### 1. Apply

```bash
sudo salt-call --local state.apply kiro.crew
```

This applies, in order:

1. **Shared + home directories** — created on the host with the right
   ownership (`home_dir` as `home_uid:home_gid`).
2. **Helper scripts** — `kirocrew-kata-login` and `kirocrew-kata-token` are
   dropped on `PATH`.
3. **CNI network** — `nerdctl network create` for the dedicated bridge with a
   fixed container IP (created only if absent).
4. **Image pull** — the image is pulled into the `kirocrew` containerd
   namespace.
5. **systemd unit** — `kirocrew-kata.service` runs the image via
   `nerdctl run --runtime io.containerd.kata-clh.v2`, enabled and started.
6. **Socket proxy** — a `kirocrew-kata-proxy.socket` + `.service` pair
   forwards `host_ip:port` into the container (see
   [architecture](#how-it-fits-together)).

Applying kata mode also tears down any `native` and `docker` mode artifacts.

### 2. First-time login

```bash
sudo kirocrew-kata-login
```

As with docker mode this is a one-time interactive device-code flow. The key
difference:

> The login container runs under **Docker** (runc), not Kata. `kiro-cli login`
> needs working outbound networking, and credentials are runtime-agnostic files
> written into the persistent `home_dir` that the Kata service mounts on start.
> Running the login under Docker sidesteps the
> [Kata-on-WSL2 networking limitation](#networking-on-wsl2), so login works even
> where the Kata service itself has no network.

The helper stops the service, runs the login container (with `--userns=host` so
uid 1000 maps to the host `home_dir` ownership), then restarts the service.

### 3. Dashboard token

```bash
sudo kirocrew-kata-token [TTL]
```

`TTL` is optional (default `2h`). The helper mints a token from the running
container and prints a URL on the published `host_ip:port`, reachable from a
host browser and, on WSL2, from Windows.

### 4. Operate

```bash
systemctl status kirocrew-kata.service
journalctl -u kirocrew-kata.service -f
sudo systemctl restart kirocrew-kata.service
```

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

Teardown stops the proxy socket and the service, removes the proxy units, kills
and removes the container via `ctr` in the `kirocrew` namespace, and removes the
service unit. The persistent `home_dir` and `shared_dir` are left in place.

## Resources (CPU / memory)

With the `clh` backend, these values **size the micro-VM**: `cpu.max` becomes
the guest vCPU count and `memory.max` becomes the guest RAM. The host must have
that much CPU and free RAM, or the VM will not boot.

| Config       | Runtime flag           | Meaning                                        |
|--------------|------------------------|------------------------------------------------|
| `cpu.max`    | `--cpus`               | Hard CPU ceiling / guest vCPUs.                |
| `cpu.min`    | `--cpu-shares`         | Relative CPU weight under contention (soft).   |
| `memory.max` | `--memory`             | Hard memory limit / guest RAM.                 |
| `memory.min` | `--memory-reservation` | Soft memory reservation / floor.               |

`*.min` values are soft: neither `--cpu-shares` nor `--memory-reservation`
preallocates capacity. Keep `memory.max` at or above `4g`.

## How it fits together

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
CNI network and a fixed container IP, and `--cpus` / `--memory` size the
micro-VM.

A CNI portmap publish is DNAT-only and has no listening socket, so WSL2 does not
mirror it to Windows. Instead a systemd `.socket` opens a real listener on
`host_ip:port` and `systemd-socket-proxyd` forwards to the container IP — which
WSL2 does mirror — while Kata VM isolation is preserved.

## Networking on WSL2

Kata micro-VM networking relies on host kernel features (tc redirect or
macvtap) to plumb a network interface into the guest. On a normal bare-metal or
KVM host this works and the Kata service has outbound networking. On **WSL2**
the kernel does not fully support these paths (the `macvtap` module cannot be
loaded and `tcfilter` redirection does not reach the guest), so a Kata
container boots with no usable network interface.

In practice:

- **Login still works**, because the helper runs under Docker (see
  [First-time login](#2-first-time-login)).
- **The Kata service itself has no outbound network** inside the micro-VM. If
  your workload needs network at runtime, use [docker mode](docker.md) on WSL2
  and reserve kata mode for bare-metal / real-KVM hosts.
