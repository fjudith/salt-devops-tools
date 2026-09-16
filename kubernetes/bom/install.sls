# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import bom with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
bom-unsupported-architecture:
  test.fail_without_changes:
    - name: "bom supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

bom-binary:
  file.managed:
    - name: /usr/local/bom/{{ bom.version }}/bom
    - source: https://github.com/kubernetes-sigs/bom/releases/download/v{{ bom.version }}/bom-{{ bin_arch }}-linux
    - source_hash: https://github.com/kubernetes-sigs/bom/releases/download/v{{ bom.version }}/checksums.txt
    - makedirs: true
    - user: root
    - group: root
    - mode: '0755'
    - unless: ls /usr/local/bom/{{ bom.version }}

bom:
  file.symlink:
    - name: /usr/local/bin/bom
    - target: /usr/local/bom/{{ bom.version }}/bom
    - mode: '0755'
{% endif %}
