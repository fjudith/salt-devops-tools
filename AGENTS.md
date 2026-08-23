# AGENTS.md

## Product

salt-ubuntu-devops-tools is a SaltStack formula collection that automates the installation and management of DevOps CLI tools on Ubuntu/Linux workstations. It provisions a local development environment with cloud CLIs (AWS, Azure, GCP), container tools (Docker, Kubernetes, Helm), infrastructure-as-code tools (Terraform, OpenTofu, Pulumi, CDK), GitOps tools (FluxCD, ArgoCD), and various other platform engineering utilities.

The project runs in masterless (salt-call --local) mode, applying states directly on the target machine. Tool selection is controlled via Salt Pillar data, where each tool has an `enabled: true/false` toggle.

Target audience: platform engineers and DevOps practitioners who want a reproducible, declarative workstation setup.

## Tech Stack

### Core Technology

- **SaltStack** (salt-minion 3008.x) — configuration management framework
- **Jinja2** — templating language used in `.sls` state files and `map.jinja`
- **YAML** — data format for defaults, pillar, and top files

### Runtime

- Target OS: Ubuntu (Debian family primary, RedHat family secondary)
- Architectures: x86_64 (amd64), aarch64 (arm64)
- Execution mode: masterless (`salt-call --local`)

### Commands

Apply all states (full provisioning):

```bash
sudo salt-call --local state.highstate
```

Apply with debug logging:

```bash
sudo salt-call --local state.highstate --file-root=/srv/salt --pillar-root=/srv/pillar --retcode-passthrough -l info
```

Apply a single state:

```bash
sudo salt-call --local state.apply <state.path>
# Example: sudo salt-call --local state.apply aws.cli
```

Test mode (dry run):

```bash
sudo salt-call --local state.highstate test=True
```

### No Build System

This project has no build/compile step. States are applied directly by the Salt minion. There are no unit tests or linting configured in the repository.

## Project Structure

### Layout

```
/srv/salt/                     # Salt file root (workspace root)
├── top.sls                    # State top file — lists all state modules applied to minions
├── pillar.sls.example         # Example pillar data (copy to /srv/pillar/devops.sls)
├── pillar.top.sls.example     # Example pillar top file
├── common/                    # Base packages state (git, jq, unzip, etc.)
├── <vendor>/                  # Tool vendor directory (e.g. aws/, hashicorp/, kubernetes/)
│   └── <tool>/                # Specific tool (e.g. cli/, helm/, nuke/)
│       ├── defaults.yaml      # Default values (version, enabled flag, URLs)
│       ├── map.jinja          # Merges defaults with pillar overrides
│       ├── init.sls           # Entry point — routes to install or teardown
│       ├── install.sls        # Installation logic
│       ├── teardown.sls       # Removal/cleanup logic
│       ├── repo.sls           # (optional) APT/YUM repository setup
│       ├── config.sls         # (optional) Configuration files, users, services
│       └── files/             # (optional) Template files (systemd units, configs)
└── /srv/pillar/               # Pillar root (external, not in this repo)
    ├── top.sls                # Pillar top file
    └── devops.sls             # Per-machine tool enablement toggles
```

### Module Conventions

Each tool module follows a consistent pattern:

1. **defaults.yaml** — defines the tool name key with `enabled: false` (safe default), `version`, and any download URLs or config values.
2. **map.jinja** — imports defaults.yaml and merges with pillar data using `salt['pillar.get']('pillar:path', default=defaults['key'], merge=True)`.
3. **init.sls** — reads the merged config via map.jinja and conditionally includes `.install` or `.teardown` based on the `enabled` flag.
4. **install.sls** — performs the actual installation (archive extraction, package install, binary download + symlink, etc.).
5. **teardown.sls** — removes installed files/binaries.

### Pillar Structure

Pillar keys mirror the directory structure. Each tool has an `enabled` boolean:

```yaml
aws:
  cli:
    enabled: true
  eksctl:
    enabled: false
```

### Naming Conventions

- Directory names use lowercase, matching vendor/project names (e.g. `openpolicyagent`, `firecracker-microvm`)
- State IDs use the tool name or `<tool>-<action>` pattern (e.g. `awscliv2`, `agentgateway-download`)
- All `.sls` and `.jinja` files include the header: `# -*- coding: utf-8 -*-` and `# vim: ft=jinja` (or `ft=yaml`)
- Jinja variables imported from map.jinja match the key name in defaults.yaml

### Installation Patterns

Tools are installed via one of these methods:
- **archive.extracted** — download and extract a tarball/zip, then run an installer script
- **file.managed + file.symlink** — download a binary, place in a versioned directory, symlink to /usr/local/bin
- **pkg.installed** — install from a system repository (requires repo.sls to add the source)
- **pkg.installed with sources** — install directly from a .deb/.rpm URL
