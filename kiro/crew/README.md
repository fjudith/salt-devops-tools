# KiroCrew service

Provisions the KiroCrew agent as a long-running service on the workstation.
The `kiro.crew` state installs the KiroCrew package and, when
`kiro:crew:service:enabled` is true, runs it in one of three modes selected by
`kiro:crew:service:mode`.

## Service modes

| Mode    | How KiroCrew runs                                             | Isolation        |
|---------|---------------------------------------------------------------|------------------|
| `native`| Installed binary managed via `kirocrew service install`       | none (host)      |
| `docker`| Docker container managed by a systemd unit (`kirocrew-docker`) | container        |
| `kata`  | OCI image inside a Kata Containers micro-VM (Cloud Hypervisor)| hardware (VM)    |

Only one mode is active at a time. Switching modes automatically tears down the
others on the next `state.apply`.

Both `docker` and `kata` modes run the container in the foreground under a
systemd unit (`Type=simple` with `Restart=always`), so the container lifecycle
follows the service: `systemctl start/stop/restart` and `systemctl status`
work as expected, and the container is removed on stop. The dashboard is
published on `host_ip:port` (default `127.0.0.1:5476`).

## First-time login

Both container modes require an authenticated `kiro-cli` session, which is an
interactive flow that cannot run during `state.apply`. Each mode ships a helper
on PATH that runs the login once against the same home the service uses, so the
credentials persist across restarts:

- `docker` mode: `sudo kirocrew-docker-login` — logs in against the
  `kirocrew-home` named volume.
- `kata` mode: `sudo kirocrew-kata-login` — logs in against the persistent
  home directory (see the Kata section).

Both helpers stop the service, run `kiro-cli login --use-device-flow` (prints a
verification URL + code to open in a browser on your host), then restart the
service.

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
```

The container runs as uid/gid 1000 (`kirocrew`). `home_dir` is created on the
host with that ownership and bind-mounted to `/home/kirocrew` so KiroCrew's
state and credentials persist across restarts and VM reboots.

### First-time login

KiroCrew requires an authenticated `kiro-cli` session. `kiro-cli login` is an
interactive flow, so it cannot run during `state.apply`. After applying the
state, run the generated helper once:

```bash
sudo kirocrew-kata-login
```

It stops the service, runs an interactive login container against the
persistent home, then restarts the service. Because credentials land in
`home_dir`, the login survives restarts — you only do this once (until the
credentials expire).

The container has no browser, so the helper uses `kiro-cli login
--use-device-flow`: it prints a verification URL and code. Open the URL in a
browser on your host, enter the code, and approve. The credentials are then
written and the container exits.

The login container runs under **Docker**, not Kata. `kiro-cli login` needs
working outbound networking, and credentials are runtime-agnostic files in the
persistent home — so it does not matter which runtime writes them. This also
sidesteps the Kata-on-WSL2 networking limitation described below.

### Networking note (WSL2)

Kata micro-VM networking relies on host kernel features (tc redirect or
macvtap) to plumb a network interface into the guest. On a normal bare-metal
or KVM host this works and the Kata service has outbound networking. On
**WSL2**, the kernel does not fully support these paths (the `macvtap` module
cannot be loaded and `tcfilter` redirection does not reach the guest), so a
Kata container boots with no usable network interface.

Practical implications on WSL2:

- Login works, because the helper uses Docker (above).
- The KiroCrew Kata service itself will have no outbound network inside the
  micro-VM. If your workload needs network at runtime, use `mode: docker` on
  WSL2 and reserve `mode: kata` for bare-metal / real-KVM hosts.

Verify afterwards:

```bash
systemctl status kirocrew-kata.service
journalctl -u kirocrew-kata.service -f
```

### How it fits together

```
kirocrew-kata.service (systemd)
  └─ ctr run --runtime io.containerd.kata-clh.v2 ...
       └─ containerd-shim-kata-clh-v2   (KATA_CONF_FILE=configuration-clh.toml)
            └─ cloud-hypervisor          (boots the micro-VM on KVM)
                 └─ virtiofsd            (shares home_dir + shared_dir into guest)
```
