# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import yq with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
yq-unsupported-architecture:
  test.fail_without_changes:
    - name: "yq supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

yq-binary:
  file.managed:
    - name: /usr/local/yq/{{ yq.version }}/yq
    - source: https://github.com/mikefarah/yq/releases/download/v{{ yq.version }}/yq_linux_{{ bin_arch }}
    - source_hash: https://github.com/mikefarah/yq/releases/download/v{{ yq.version }}/checksums
    - skip_verify: true
    - makedirs: true
    - user: root
    - group: root
    - mode: '0755'
    - unless: ls /usr/local/yq/{{ yq.version }}

yq:
  file.symlink:
    - name: /usr/local/bin/yq
    - target: /usr/local/yq/{{ yq.version }}/yq
    - mode: '0755'
{% endif %}
