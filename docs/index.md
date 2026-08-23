# Salt Ubuntu DevOps Tools

SaltStack formula collection that automates the installation and management of DevOps CLI tools on Ubuntu/Linux workstations.

## Overview

This project provisions a local development environment with:

- Cloud CLIs (AWS, Azure, GCP, Hetzner, Scaleway)
- Container tools (Docker, Kubernetes, Helm, K9s, Kind)
- Infrastructure-as-Code (Terraform, OpenTofu, Pulumi, Crossplane)
- GitOps (FluxCD, ArgoCD, Weave GitOps)
- Security (Trivy, Falco, Kyverno, OPA/Conftest)
- Serverless (OpenFaaS, Fission, Nuclio)
- Observability (Prometheus, Pixie, OpenCost, Sloth)
- AI/Agent tooling (Kiro, AgentGateway)
- Certificate management (IAM Roles Anywhere CA)

## How It Works

The project runs in **masterless** mode (`salt-call --local`), applying states directly on the target machine. Tool selection is controlled via Salt Pillar data where each tool has an `enabled: true/false` toggle.

## Requirements

- Ubuntu (Debian family) or RHEL-based Linux
- Salt minion 3008.x
- Architectures: x86_64 (amd64), aarch64 (arm64)

## Quick Start

### Enable passwordless sudo

```bash
cat <<EOF | sudo tee /etc/sudoers.d/$(id -un)
$(id -un) ALL=(ALL:ALL) NOPASSWD:ALL
EOF
```

### Install Salt

```bash
cat <<EOF | sudo tee /etc/apt/preferences.d/salt-pin-1001
Package: salt-*
Pin: version 3008.*
Pin-Priority: 1001
EOF
curl -fsSL https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public \
| sudo tee /etc/apt/keyrings/salt-archive-keyring.pgp \
&& echo "deb [signed-by=/etc/apt/keyrings/salt-archive-keyring.pgp arch=amd64] https://packages.broadcom.com/artifactory/saltproject-deb stable main" \
| sudo tee /etc/apt/sources.list.d/salt.list \
&& sudo apt-get update -yqq \
&& sudo apt-get install -yqq salt-minion
```

### Clone and configure

```bash
sudo git clone https://github.com/fjudith/salt-ubuntu-devops-tools /srv/salt \
&& sudo chown -R $(id -un) /srv/salt

sudo mkdir -vp /srv/pillar \
&& sudo chown $(id -un) /srv/pillar \
&& cp -vf /srv/salt/pillar.sls.example /srv/pillar/devops.sls \
&& cp -vf /srv/salt/pillar.top.sls.example /srv/pillar/top.sls
```

Edit `/srv/pillar/devops.sls` to enable/disable tools.

### Apply

```bash
sudo salt-call --local state.highstate
```

## Module Structure

Each tool follows a consistent pattern:

| File | Purpose |
|------|---------|
| `defaults.yaml` | Default values (version, enabled flag, URLs) |
| `map.jinja` | Merges defaults with pillar overrides |
| `init.sls` | Entry point — routes to install or teardown |
| `install.sls` | Installation logic |
| `teardown.sls` | Removal/cleanup logic |
| `repo.sls` | (optional) APT/YUM repository setup |
| `config.sls` | (optional) Configuration files, users, services |
| `files/` | (optional) Template files (systemd units, configs) |

## Useful Commands

| Command | Description |
|---------|-------------|
| `sudo salt-call --local state.highstate` | Full provisioning |
| `sudo salt-call --local state.apply <state>` | Apply a single state |
| `sudo salt-call --local state.highstate test=True` | Dry run |
| `sudo salt-call --local state.highstate -l info` | Debug logging |
