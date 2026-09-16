# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import kubestack with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
kbst-unsupported-architecture:
  test.fail_without_changes:
    - name: "kbst supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

kubestack-archive:
  archive.extracted:
    - name: /usr/local/kubestack/{{ kubestack.version }}
    - source: https://github.com/kbst/kbst/releases/download/v{{ kubestack.version }}/kbst_linux_{{ bin_arch }}.zip
    - source_hash: https://github.com/kbst/kbst/releases/download/v0.2.1/kbst_v0.2.1_SHA256SUMS
    - skip_verify: false
    - user: root
    - group: root
    - archive_format: zip
    - enforce_toplevel: false
    - unless: ls /usr/local/kubestack/{{ kubestack.version }}

kubestack:
  file.symlink:
    - name: /usr/local/bin/kbst
    - target: /usr/local/kubestack/{{ kubestack.version }}/kbst

kubestack-completion:
  cmd.run:
    - require:
      - archive: kubestack-archive
    - name: /usr/local/bin/kbst completion bash > /etc/bash_completion.d/kubestack
{% endif %}
