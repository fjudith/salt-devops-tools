# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import sops with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
sops-unsupported-architecture:
  test.fail_without_changes:
    - name: "sops supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

sops-binary:
  file.managed:
    - name: /usr/local/sops/{{ sops.version }}/sops
    - source: https://github.com/getsops/sops/releases/download/v{{ sops.version }}/sops-v{{ sops.version }}.linux.{{ bin_arch }}
    - source_hash: https://github.com/getsops/sops/releases/download/v{{ sops.version }}/sops-v{{ sops.version }}.checksums.txt
    - makedirs: true
    - user: root
    - group: root
    - mode: 755
    - unless: ls /usr/local/sops/{{ sops.version }}

sops:
  file.symlink:
    - name: /usr/local/bin/sops
    - target: /usr/local/sops/{{ sops.version }}/sops
    - mode: 755
{% endif %}
