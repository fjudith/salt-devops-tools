# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import hubble with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
hubble-unsupported-architecture:
  test.fail_without_changes:
    - name: "hubble supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

hubble-archive:
  archive.extracted:
    - name: /usr/local/hubble/{{ hubble.version }}
    - source: https://github.com/cilium/hubble/releases/download/v{{ hubble.version }}/hubble-linux-{{ bin_arch }}.tar.gz
    - source_hash: https://github.com/cilium/hubble/releases/download/v{{ hubble.version }}/hubble-linux-{{ bin_arch }}.tar.gz.sha256sum
    - skip_verify: false
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    - unless: ls /usr/local/hubble/{{ hubble.version }}

hubble:
  file.symlink:
    - name: /usr/local/bin/hubble
    - target: /usr/local/hubble/{{ hubble.version }}/hubble

hubble-completion:
  cmd.run:
    - require:
      - file: hubble
    - name: /usr/local/bin/hubble completion bash | tee /etc/bash_completion.d/hubble
{% endif %}
