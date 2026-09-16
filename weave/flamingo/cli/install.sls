# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import flamingo with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
flamingo-unsupported-architecture:
  test.fail_without_changes:
    - name: "flamingo supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

flamingo-archive:
  archive.extracted:
    - name: /usr/local/flamingo/{{ flamingo.version }}
    - source: https://github.com/flux-subsystem-argo/flamingo/releases/download/v{{ flamingo.version }}/flamingo_{{ flamingo.version }}_linux_{{ bin_arch }}.tar.gz
    - source_hash: https://github.com/flux-subsystem-argo/flamingo/releases/download/v{{ flamingo.version }}/flamingo_{{ flamingo.version }}_checksums.txt
    - skip_verify: false
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    - unless: ls /usr/local/flamingo/{{ flamingo.version }}

flamingo:
  file.symlink:
    - name: /usr/local/bin/flamingo
    - target: /usr/local/flamingo/{{ flamingo.version }}/flamingo
{% endif %}
