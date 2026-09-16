# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import cilium with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
cilium-unsupported-architecture:
  test.fail_without_changes:
    - name: "cilium supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

cilium-archive:
  archive.extracted:
    - name: /usr/local/cilium/{{ cilium.version }}
    - source: https://github.com/cilium/cilium-cli/releases/download/v{{ cilium.version }}/cilium-linux-{{ bin_arch }}.tar.gz
    - source_hash: https://github.com/cilium/cilium-cli/releases/download/v{{ cilium.version }}/cilium-linux-{{ bin_arch }}.tar.gz.sha256sum
    - skip_verify: false
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    - unless: ls /usr/local/cilium/{{ cilium.version }}

cilium:
  file.symlink:
    - name: /usr/local/bin/cilium
    - target: /usr/local/cilium/{{ cilium.version }}/cilium

cilium-completion:
  cmd.run:
    - require:
      - file: cilium
    - name: /usr/local/bin/cilium completion bash | tee /etc/bash_completion.d/cilium
{% endif %}
