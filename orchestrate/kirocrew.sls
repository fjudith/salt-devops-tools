# -*- coding: utf-8 -*-
# vim: ft=jinja
#
# Orchestration state for KiroCrew.
#
# Coordinates the ordered application of KiroCrew and every prerequisite
# formula it depends on, based on the selected service mode. Because this
# project runs masterless, invoke it with the local orchestrate runner:
#
#   sudo salt-call --local state.orchestrate orchestrate.kirocrew \
#     --file-root=/srv/salt --pillar-root=/srv/pillar
#
# Each step targets the local minion via the salt.state orchestration module.
# The `require` chain enforces the correct install order; the `kiro.crew`
# state itself still performs the per-mode teardown of the inactive modes.

{% set kirocrew = salt['pillar.get']('kiro:crew', default={}) %}
{% set enabled = kirocrew.get('enabled', False) %}
{% set service = kirocrew.get('service', {}) %}
{% set service_enabled = service.get('enabled', False) %}
{% set mode = service.get('mode', 'native') %}

{#- Resolve the local minion id so orchestration targets this host only. #}
{% set this = grains['id'] %}

{% if enabled and service_enabled and mode == 'kata' %}
{#- kata: needs containerd (docker formula), Cloud Hypervisor, Kata Containers,
    nerdctl, and the Kiro CLI before KiroCrew. #}

kirocrew-orch-common:
  salt.state:
    - tgt: {{ this }}
    - sls:
      - common

kirocrew-orch-docker:
  salt.state:
    - tgt: {{ this }}
    - sls:
      - docker
    - require:
      - salt: kirocrew-orch-common

kirocrew-orch-cloud-hypervisor:
  salt.state:
    - tgt: {{ this }}
    - sls:
      - cloud-hypervisor.cloud-hypervisor
    - require:
      - salt: kirocrew-orch-docker

kirocrew-orch-kata-containers:
  salt.state:
    - tgt: {{ this }}
    - sls:
      - kata-containers.kata-containers
    - require:
      - salt: kirocrew-orch-cloud-hypervisor

kirocrew-orch-nerdctl:
  salt.state:
    - tgt: {{ this }}
    - sls:
      - containerd.nerdctl
    - require:
      - salt: kirocrew-orch-kata-containers

kirocrew-orch-kiro-cli:
  salt.state:
    - tgt: {{ this }}
    - sls:
      - kiro.cli
    - require:
      - salt: kirocrew-orch-nerdctl

kirocrew-orch-crew:
  salt.state:
    - tgt: {{ this }}
    - sls:
      - kiro.crew
    - require:
      - salt: kirocrew-orch-kiro-cli

{% elif enabled and service_enabled and mode == 'docker' %}
{#- docker: needs the docker formula and the Kiro CLI before KiroCrew. #}

kirocrew-orch-common:
  salt.state:
    - tgt: {{ this }}
    - sls:
      - common

kirocrew-orch-docker:
  salt.state:
    - tgt: {{ this }}
    - sls:
      - docker
    - require:
      - salt: kirocrew-orch-common

kirocrew-orch-kiro-cli:
  salt.state:
    - tgt: {{ this }}
    - sls:
      - kiro.cli
    - require:
      - salt: kirocrew-orch-docker

kirocrew-orch-crew:
  salt.state:
    - tgt: {{ this }}
    - sls:
      - kiro.crew
    - require:
      - salt: kirocrew-orch-kiro-cli

{% else %}
{#- native mode (or service disabled / KiroCrew disabled): just the base
    packages and the Kiro CLI before KiroCrew. The kiro.crew state handles
    tearing down any container-mode artifacts. #}

kirocrew-orch-common:
  salt.state:
    - tgt: {{ this }}
    - sls:
      - common

kirocrew-orch-kiro-cli:
  salt.state:
    - tgt: {{ this }}
    - sls:
      - kiro.cli
    - require:
      - salt: kirocrew-orch-common

kirocrew-orch-crew:
  salt.state:
    - tgt: {{ this }}
    - sls:
      - kiro.crew
    - require:
      - salt: kirocrew-orch-kiro-cli

{% endif %}
