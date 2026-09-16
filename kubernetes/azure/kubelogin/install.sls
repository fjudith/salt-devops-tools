# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import azurekubelogin with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
kubelogin-unsupported-architecture:
  test.fail_without_changes:
    - name: "kubelogin supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

azurekubelogin-archive:
  archive.extracted:
    - name: /usr/local/azure-kubelogin/{{ azurekubelogin.version }}
    - source: https://github.com/Azure/kubelogin/releases/download/v{{ azurekubelogin.version }}/kubelogin-linux-{{ bin_arch }}.zip
    - source_hash: https://github.com/Azure/kubelogin/releases/download/v{{ azurekubelogin.version }}/kubelogin-linux-{{ bin_arch }}.zip.sha256
    - skip_verify: false
    # - user: root
    # - group: root
    - archive_format: zip
    - enforce_toplevel: false
    - options: '-j'  # junk paths (do not make directories)
    - unless: ls /usr/local/azure-kubelogin/{{ azurekubelogin.version }}

azurekubelogin:
  file.symlink:
    - name: /usr/local/bin/kubelogin
    - target: /usr/local/azure-kubelogin/{{ azurekubelogin.version }}/kubelogin
{% endif %}
