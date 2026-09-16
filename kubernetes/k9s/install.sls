# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import k9s with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
k9s-unsupported-architecture:
  test.fail_without_changes:
    - name: "k9s supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

k9s-archive:
  archive.extracted:
    - name: /usr/local/k9s/{{ k9s.version }}
    - source: https://github.com/derailed/k9s/releases/download/v{{ k9s.version }}/k9s_Linux_{{ bin_arch }}.tar.gz
    - source_hash: https://github.com/derailed/k9s/releases/download/v{{ k9s.version }}/checksums.sha256
    - skip_verify: false
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    - unless: ls /usr/local/k9s/{{ k9s.version }}

k9s:
  file.symlink:
    - name: /usr/local/bin/k9s
    - target: /usr/local/k9s/{{ k9s.version }}/k9s
{% endif %}
