# oh-my-pi (omp) Formula

Installs [oh-my-pi](https://github.com/can1357/oh-my-pi) — `omp`, a coding agent
with the IDE wired in (a fork of [Pi](https://github.com/badlogic/pi-mono) by
Mario Zechner).

This formula installs the prebuilt release binary published on GitHub, matching
the behaviour of the upstream `curl -fsSL https://omp.sh/install | sh` installer
(binary mode). It does **not** use the bun/source install path.

## States

| State | Purpose |
|-------|---------|
| `init.sls` | Entry point — routes to install or teardown based on `enabled` |
| `install.sls` | Downloads the release binary, verifies its checksum, symlinks to `/usr/local/bin/omp`, installs bash completion |
| `teardown.sls` | Removes the binary, symlink, and completion script |

## Architecture / libc detection

The correct asset is selected automatically from grains and the host libc:

| Host | Asset |
|------|-------|
| x86_64 (glibc) | `omp-linux-x64` |
| aarch64 (glibc) | `omp-linux-arm64` |
| x86_64 (musl / Alpine) | `omp-linux-musl-x64` |
| aarch64 (musl / Alpine) | `omp-linux-musl-arm64` |

> **Alpine / musl note:** the musl build links `libstdc++`/`libgcc` dynamically,
> which stock Alpine does not ship. Install them first with
> `apk add libstdc++ libgcc`.

Checksums are verified against the release `SHA256SUMS.txt`.

## File Layout

```
/usr/local/oh-my-pi/<version>/omp    # Versioned binary
/usr/local/bin/omp                   # Symlink
/etc/bash_completion.d/omp           # Bash completion (when completion: true)
```

## Pillar Configuration

```yaml
oh-my-pi:
  omp:
    enabled: true
    version: 18.1.2
    base_url: https://github.com/can1357/oh-my-pi/releases/download
    install_dir: /usr/local/oh-my-pi
    bin_dir: /usr/local/bin
    completion: true
```

## Apply

```bash
sudo salt-call --local state.apply oh-my-pi.omp
```
