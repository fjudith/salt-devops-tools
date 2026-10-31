# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import codegraph with context %}

{#- Detect architecture -> release asset target suffix #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch in ('x86_64', 'amd64') %}
  {% set target = 'linux-x64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set target = 'linux-arm64' %}
{% endif %}

{% if target is not defined %}
codegraph-unsupported-architecture:
  test.fail_without_changes:
    - name: "codegraph supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

{% set asset = 'codegraph-' ~ target ~ '.tar.gz' %}
{% set download_url = codegraph.base_url ~ '/' ~ codegraph.version ~ '/' ~ asset %}
{% set version_dir = codegraph.install_dir ~ '/versions/' ~ codegraph.version %}

codegraph-archive:
  archive.extracted:
    - name: {{ version_dir }}
    - source: {{ download_url }}
    # Renovate bumps `version` but cannot update a pinned checksum, so skip
    # verification to avoid stale-hash failures (same approach as kubernetes.helm).
    - skip_verify: true
    - user: root
    - group: root
    - archive_format: tar
    # Archives contain a top-level codegraph-<target>/ dir; strip it.
    - options: --strip-components=1
    - enforce_toplevel: false
    - unless: ls {{ version_dir }}/bin/codegraph

codegraph-symlink:
  file.symlink:
    - name: {{ codegraph.bin_dir }}/codegraph
    - target: {{ version_dir }}/bin/codegraph
    - force: true
    - require:
      - archive: codegraph-archive

{% endif %}
