# salt-ubuntu-devops-tools

> **Windows Users**: [Setup appropriate WSL engine](./WSL2.md)

## Enable passwordless sudo

Run the following command line to enable passwordless sudo access.

```bash
cat <<EOF | sudo tee /etc/sudoers.d/$(id -un)
$(id -un) ALL=(ALL:ALL) NOPASSWD:ALL
EOF
```

## Install Salt

```bash
cat <<EOF | sudo tee /etc/apt/preferences.d/salt-pin-1001
echo 'Package: salt-*
Pin: version 3006.*
Pin-Priority: 1001'
EOF
curl -fsSL https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public | sudo tee /etc/apt/keyrings/salt-archive-keyring.pgp
&& curl -fsSL https://github.com/saltstack/salt-install-guide/releases/latest/download/salt.sources | sudo tee /etc/apt/sources.list.d/salt.list
&& sudo apt-get update -y \
&& sudo apt-get install -y git salt-minion
```

## Clone this repo

Run the following commands to clone the repository and set appropriate permissions.

```bash
sudo git clone https://github.com/fjudith/salt-ubuntu-devops-tools /srv/salt \
&& sudo chown -R $(id -un) /srv/salt
```


## Deploy Salt Pillar from the example

Run the following commands to configure the pillar.

```bash
sudo mkdir -vp /srv/pillar \
&& sudo chown $(id -un) /srv/pillar \
&& cp -vf /srv/salt/pillar.sls.example /srv/pillar/devops.sls \
&& cp -vf /srv/salt/pillar.top.sls.example /srv/pillar/top.sls
```

Edit the `/srv/pillar/devops.sls` to customize installed tools.

**example**:

```yaml
common:
  enabled: true
aquasecurity:
  trivy:
    enabled: true
  falco:
    enabled: false
hashicorp:
  terraform:
    cli:
      enabled: true
pulumi:
  cli:
    enabled: false
kubernetes:
  cli:
    enabled: true
  helm:
    enabled: true
```

## Installation

Run the following command to install the tools locally with Salt (i.e. Salt Masterless)

```bash
sudo salt-call --local state.highstate
```

**Debug only**:

```bash
sudo salt-call --local  state.highstate --file-root=/srv/salt --pillar-root=/srv/pillar --retcode-passthrough -l info
```
