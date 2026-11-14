# Docker Formula

This formula installs Docker on your Ubuntu workstation. You get Docker Engine, the `docker` command, Buildx and Compose from the official Docker apt repository. You can also turn on a few extra tools. It works on Ubuntu only.

## Quick start

1. Copy `pillar.sls.example` to `/srv/pillar/devops.sls` if you have not done it yet. The default `docker:` settings install Engine, CLI, Buildx and Compose. Add extra tools in the same `docker:` block (see below).
2. Apply the state:

   ```bash
   sudo salt-call --local state.apply docker
   ```

   `sudo salt-call --local state.highstate` also applies it, together with your other tools.
3. Check that it works:

   ```bash
   docker version
   docker compose version
   docker run --rm hello-world
   ```

The formula does not add your user to the `docker` group. Until you do, put `sudo` in front of `docker` commands, or run this once and log in again:

```bash
sudo usermod -aG docker $USER
```

## What is installed

| Tool | What it is | On by default | Pillar key |
|------|------------|---------------|------------|
| Docker Engine | The container engine (daemon) | Yes | `daemon` |
| Docker CLI | The `docker` command | Yes | `cli` |
| Buildx | Extended image builds with BuildKit | Yes | `buildx_plugin` |
| Compose | The `docker compose` command | Yes | `compose_plugin` |
| Model Runner | The `docker model` command | No | `model_plugin` |
| Docker Sandboxes (sbx) | Docker sbx | No | `sbx` |
| Secrets Engine | Per-user service that gives access to stored credentials, with a `docker-pass` command | No | `secrets_engine` and `secrets_engine_plugins` |
| cagent | Multi-agent AI runtime | No | `cagent` |
| Docker Scout | Image security and supply chain analysis (`docker scout`) | Yes | `scout_plugin` |

## Turn a tool on or off

Edit `/srv/pillar/devops.sls`. This example enables Model Runner and turns off Docker Scout, which is on by default:

```yaml
docker:
  model_plugin:
    enabled: true
  scout_plugin:
    enabled: false
```

Apply it again:

```bash
sudo salt-call --local state.apply docker
```

Then check the tools. If a command does not print help, the tool is not installed:

```bash
docker model --help
```

To remove a tool, set `enabled: false` and apply again. The Docker apt repository, `containerd.io` and the Docker service stay in place.

## Things to know

- Enable `secrets_engine` and `secrets_engine_plugins` together, and give them the same version. If you enable only the plugins, the next apply removes both packages.
- `sbx` installs many extra packages.
- Versions are pinned. Renovate pull requests update them for most tools. `sbx` and `cagent` are updated by hand, because their versions must exist in the Docker apt repository.
- Docker runs with user namespace remapping (`"userns-remap": "default"` in `/etc/docker/daemon.json`). Files created by containers in bind-mounted folders can belong to a different user on your host. GPU containers may also fail.
- `nvidia_runtime: true` adds the NVIDIA runtime to the Docker configuration. It needs the `nvidia.container_toolkit` state to be enabled too.

## Troubleshooting

- **`permission denied` on `/var/run/docker.sock`**: use `sudo`, or add yourself to the `docker` group (see Quick start).
- **`docker: 'scout' is not a docker command`**: set `scout_plugin.enabled: true` and apply the state again.
- **Apt cannot find the pinned version**: the version is not in the Docker repository for your Ubuntu release. Run `apt-cache madison <package>` and set `version` to one that is listed.
- **Scout fails with `docker-scout-unsupported-architecture`**: Scout only supports x86_64 and aarch64 CPUs.

## More settings

Every available setting is in `/srv/salt/docker/defaults.yaml`. Examples are in `/srv/salt/pillar.sls.example`.
