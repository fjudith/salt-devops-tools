# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import scw with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
scw-unsupported-architecture:
  test.fail_without_changes:
    - name: "scaleway-cli supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

scaleway-cli-binary:
  file.managed:
    - name: /usr/local/scaleway/{{ scw.version }}/scaleway-cli
    - source: https://github.com/scaleway/scaleway-cli/releases/download/v{{ scw.version }}/scaleway-cli_{{ scw.version }}_linux_{{ bin_arch }}
    - source_hash: https://github.com/scaleway/scaleway-cli/releases/download/v{{ scw.version }}/SHA256SUMS
    - makedirs: true
    - user: root
    - group: root
    - mode: 755
    - unless: ls /usr/local/scaleway/{{ scw.version }}

scaleway-cli:
  file.symlink:
    - name: /usr/local/bin/scaleway-cli
    - target: /usr/local/scaleway/{{ scw.version }}/scaleway-cli
    - mode: 755

scw:
  file.symlink:
    - name: /usr/local/bin/scw
    - target: /usr/local/scaleway/{{ scw.version }}/scaleway-cli
    - mode: 755
{% endif %}
