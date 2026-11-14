# -*- coding: utf-8 -*-
# vim: ft=jinja
{% from tpldir ~ "/map.jinja" import goose with context %}
{#- Detect architecture -> release asset target triple #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch in ('x86_64', 'amd64') %}
  {% set target = 'x86_64-unknown-linux-gnu' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set target = 'aarch64-unknown-linux-gnu' %}
{% endif %}
{% if target is not defined %}
goose-unsupported-architecture:
  test.fail_without_changes:
    - name: "goose supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}
{% set asset = 'goose-' ~ target ~ '.tar.gz' %}
{% set download_url = goose.base_url ~ '/' ~ goose.version ~ '/' ~ asset %}
{% set version_dir = goose.install_dir ~ '/versions/' ~ goose.version %}
goose-archive:
  archive.extracted:
    - name: {{ version_dir }}
    - source: {{ download_url }}
    # Renovate bumps `version` but cannot update a pinned checksum, so skip
    # verification to avoid stale-hash failures (same approach as codegraph.cli).
    - skip_verify: true
    - user: root
    - group: root
    - archive_format: tar
    # Archive is flat (./goose), nothing to strip.
    - enforce_toplevel: false
    - unless: ls {{ version_dir }}/goose
goose-symlink:
  file.symlink:
    - name: {{ goose.bin_dir }}/goose
    - target: {{ version_dir }}/goose
    - force: true
    - require:
      - archive: goose-archive
{% endif %}
