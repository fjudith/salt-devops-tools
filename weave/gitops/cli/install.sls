# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import gitops with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'x86_64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
gitops-unsupported-architecture:
  test.fail_without_changes:
    - name: "gitops supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

gitops-archive:
  archive.extracted:
    - name: /usr/local/gitops/{{ gitops.version }}
    - source: https://github.com/weaveworks/weave-gitops/releases/download/v{{ gitops.version }}/gitops-Linux-{{ bin_arch }}.tar.gz
    - source_hash: https://github.com/weaveworks/weave-gitops/releases/download/v{{ gitops.version }}/gitops_checksums.txt
    - skip_verify: false
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    - unless: ls /usr/local/gitops/{{ gitops.version }}

gitops:
  file.symlink:
    - name: /usr/local/bin/gitops
    - target: /usr/local/gitops/{{ gitops.version }}/gitops
{% endif %}
