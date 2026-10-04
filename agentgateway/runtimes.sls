# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import agentgateway with context %}

{% set uv = agentgateway.runtimes.uv %}
{% set node = agentgateway.runtimes.node %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set uv_arch = 'x86_64' %}
  {% set node_arch = 'x64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set uv_arch = 'aarch64' %}
  {% set node_arch = 'arm64' %}
{% endif %}

{% if uv_arch is not defined %}
agentgateway-runtimes-unsupported-architecture:
  test.fail_without_changes:
    - name: "agentgateway runtimes support x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

agentgateway-runtime-dir:
  file.directory:
    - name: {{ agentgateway.runtime_dir }}
    - user: root
    - group: root
    - mode: '0755'
    - makedirs: true

agentgateway-cache-dir:
  file.directory:
    - names:
      - {{ agentgateway.cache_dir }}
      - {{ agentgateway.cache_dir }}/uv
      - {{ agentgateway.cache_dir }}/uv/python
      - {{ agentgateway.cache_dir }}/npm
      - {{ agentgateway.cache_dir }}/xdg
    - user: {{ agentgateway.user }}
    - group: {{ agentgateway.group }}
    - mode: '0750'
    - makedirs: true
    - require:
      - file: agentgateway-runtime-dir

{% if uv.enabled %}
agentgateway-uv-archive:
  archive.extracted:
    - name: {{ agentgateway.runtime_dir }}/uv/{{ uv.version }}
    - source: {{ uv.base_url }}/{{ uv.version }}/uv-{{ uv_arch }}-unknown-linux-gnu.tar.gz
    - source_hash: {{ uv.base_url }}/{{ uv.version }}/uv-{{ uv_arch }}-unknown-linux-gnu.tar.gz.sha256
    - skip_verify: false
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    - options: --strip-components=1
    - unless: ls {{ agentgateway.runtime_dir }}/uv/{{ uv.version }}/uvx
    - require:
      - file: agentgateway-runtime-dir

agentgateway-uv-symlink:
  file.symlink:
    - name: {{ agentgateway.runtime_dir }}/uv/uv
    - target: {{ agentgateway.runtime_dir }}/uv/{{ uv.version }}/uv
    - force: true
    - require:
      - archive: agentgateway-uv-archive

agentgateway-uvx-symlink:
  file.symlink:
    - name: {{ agentgateway.runtime_dir }}/uv/uvx
    - target: {{ agentgateway.runtime_dir }}/uv/{{ uv.version }}/uvx
    - force: true
    - require:
      - archive: agentgateway-uv-archive
{% endif %}

{% if node.enabled %}
agentgateway-node-archive:
  archive.extracted:
    - name: {{ agentgateway.runtime_dir }}/node/{{ node.version }}
    - source: {{ node.base_url }}/v{{ node.version }}/node-v{{ node.version }}-linux-{{ node_arch }}.tar.xz
    - source_hash: {{ node.base_url }}/v{{ node.version }}/SHASUMS256.txt
    - skip_verify: false
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    - options: --strip-components=1
    - unless: ls {{ agentgateway.runtime_dir }}/node/{{ node.version }}/bin/node
    - require:
      - file: agentgateway-runtime-dir

agentgateway-node-bin-symlink:
  file.symlink:
    - name: {{ agentgateway.runtime_dir }}/node/bin
    - target: {{ agentgateway.runtime_dir }}/node/{{ node.version }}/bin
    - force: true
    - require:
      - archive: agentgateway-node-archive
{% endif %}

{% endif %}
