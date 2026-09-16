# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import fission with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
fission-unsupported-architecture:
  test.fail_without_changes:
    - name: "fission supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

fission-binary:
  file.managed:
    - name: /usr/local/fission/{{ fission.version }}/fission-linux-{{ bin_arch }}
    - source: https://github.com/fission/fission/releases/download/v{{ fission.version }}/fission-v{{ fission.version }}-linux-{{ bin_arch }}
    - source_hash: https://github.com/fission/fission/releases/download/v{{ fission.version }}/fission-v{{ fission.version }}-linux-{{ bin_arch }}.sig
    - skip_verify: true
    - makedirs: true
    - user: root
    - group: root
    - mode: 755
    - unless: ls /usr/local/fission/{{ fission.version }}

fission:
  file.symlink:
    - name: /usr/local/bin/fission
    - target: /usr/local/fission/{{ fission.version }}/fission-linux-{{ bin_arch }}
    - mode: 755
{% endif %}
