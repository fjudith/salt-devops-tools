# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import firecracker with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'x86_64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'aarch64' %}
{% endif %}

{% if bin_arch is not defined %}
firecracker-unsupported-architecture:
  test.fail_without_changes:
    - name: "firecracker supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

firecracker-archive:
  archive.extracted:
    - name: /usr/local/firecracker/{{ firecracker.version }}
    - source: https://github.com/firecracker-microvm/firecracker/releases/download/v{{ firecracker.version }}/firecracker-v{{ firecracker.version }}-{{ bin_arch }}.tgz
    - source_hash: https://github.com/firecracker-microvm/firecracker/releases/download/v{{ firecracker.version }}/firecracker-v{{ firecracker.version }}-{{ bin_arch }}.tgz.sha256.txt
    - skip_verify: false
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    - unless: ls /usr/local/firecracker/{{ firecracker.version }}

firecracker:
  file.symlink:
    - name: /usr/local/bin/firecracker
    - target: /usr/local/firecracker/{{ firecracker.version }}/release-v{{ firecracker.version }}-{{ bin_arch }}/firecracker-v{{ firecracker.version }}-{{ bin_arch }}
{% endif %}
