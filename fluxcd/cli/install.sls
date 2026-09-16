# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import fluxcd with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
flux-unsupported-architecture:
  test.fail_without_changes:
    - name: "flux supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

fluxcd-archive:
  archive.extracted:
    - name: /usr/local/fluxcd/{{ fluxcd.version }}
    - source: https://github.com/fluxcd/flux2/releases/download/v{{ fluxcd.version }}/flux_{{ fluxcd.version }}_linux_{{ bin_arch }}.tar.gz
    - source_hash: https://github.com/fluxcd/flux2/releases/download/v{{ fluxcd.version }}/flux_{{ fluxcd.version }}_checksums.txt
    - skip_verify: false
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    - unless: ls /usr/local/fluxcd/{{ fluxcd.version }}

fluxcd:
  file.symlink:
    - name: /usr/local/bin/flux
    - target: /usr/local/fluxcd/{{ fluxcd.version }}/flux

fluxcd-completion:
  cmd.run:
    - require:
      - file: fluxcd
    - name: /usr/local/bin/flux completion bash > /etc/bash_completion.d/flux
{% endif %}
