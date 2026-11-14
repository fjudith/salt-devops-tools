# -*- coding: utf-8 -*-
# vim: ft=jinja

{%- from tpldir ~ "/map.jinja" import docker with context %}

# The containerd.io package is managed by the standalone containerd.containerd
# state. The docker daemon depends on it, so it is installed first.
include:
  - containerd.containerd

docker-ce:
  {%- if docker.daemon.enabled %}
  pkg.installed:
    - version: '5:{{ docker.daemon.version }}-1~ubuntu.{{ grains["osrelease"] }}~{{ grains["oscodename"] }}'
    - require:
      - sls: containerd.containerd
  {%- else %}}
  pkg.absent:
  {%- endif %}

docker-ce-cli:
  {%- if docker.cli.enabled %}
  pkg.installed:
    - version: '5:{{ docker.cli.version }}-1~ubuntu.{{ grains["osrelease"] }}~{{ grains["oscodename"] }}'
  {%- else %}}
  pkg.absent:
  {%- endif %}

docker-buildx-plugin:
  {%- if docker.buildx_plugin.enabled %}
  pkg.installed:
    - version: '{{ docker.buildx_plugin.version }}-1~ubuntu.{{ grains["osrelease"] }}~{{ grains["oscodename"] }}'
  {%- else %}}
  pkg.absent:
  {%- endif %}

docker-compose-plugin:
  {%- if docker.compose_plugin.enabled %}
  pkg.installed:
    - version: '{{ docker.compose_plugin.version }}-1~ubuntu.{{ grains["osrelease"] }}~{{ grains["oscodename"] }}'
  {%- else %}}
  pkg.absent:
  {%- endif %}
docker-model-plugin:
  {%- if docker.model_plugin.enabled %}
  pkg.installed:
    - version: '{{ docker.model_plugin.version }}-1~ubuntu.{{ grains["osrelease"] }}~{{ grains["oscodename"] }}'
  {%- else %}
  pkg.absent
  {%- endif %}
docker-sbx:
  {%- if docker.sbx.enabled %}
  pkg.installed:
    - version: '{{ docker.sbx.version }}-1~ubuntu.{{ grains["osrelease"] }}~{{ grains["oscodename"] }}'
  {%- else %}
  pkg.absent
  {%- endif %}
docker-secrets-engine:
  {%- if docker.secrets_engine.enabled %}
  pkg.installed:
    - version: '{{ docker.secrets_engine.version }}~ubuntu.{{ grains["osrelease"] }}~{{ grains["oscodename"] }}'
  {%- else %}
  pkg.absent
  {%- endif %}
docker-secrets-engine-plugins:
  {%- if docker.secrets_engine_plugins.enabled %}
  pkg.installed:
    - version: '{{ docker.secrets_engine_plugins.version }}~ubuntu.{{ grains["osrelease"] }}~{{ grains["oscodename"] }}'
  {%- else %}
  pkg.absent
  {%- endif %}
cagent:
  {%- if docker.cagent.enabled %}
  pkg.installed:
    - version: '{{ docker.cagent.version }}-1~ubuntu.{{ grains["osrelease"] }}~{{ grains["oscodename"] }}'
  {%- else %}
  pkg.absent
  {%- endif %}
