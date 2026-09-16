# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import sloth with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
sloth-unsupported-architecture:
  test.fail_without_changes:
    - name: "sloth supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

sloth-binary:
  file.managed:
    - name: /usr/local/sloth/{{ sloth.version }}/sloth
    - source: https://github.com/slok/sloth/releases/download/v{{ sloth.version }}/sloth-linux-{{ bin_arch }}
    - source_hash: https://github.com/slok/sloth/releases/download/v{{ sloth.version }}/checksums.txt
    - makedirs: true
    - user: root
    - group: root
    - mode: '0755'
    - unless: ls /usr/local/sloth/{{ sloth.version }}

sloth:
  file.symlink:
    - name: /usr/local/bin/sloth
    - target: /usr/local/sloth/{{ sloth.version }}/sloth
    - mode: '0755'
{% endif %}
