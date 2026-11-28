# -*- coding: utf-8 -*-
# vim: ft=jinja
{% from tpldir ~ "/map.jinja" import uv with context %}
{#- Detect architecture -> release asset target triple #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch in ('x86_64', 'amd64') %}
  {% set target = 'x86_64-unknown-linux-gnu' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set target = 'aarch64-unknown-linux-gnu' %}
{% endif %}
{% if target is not defined %}
uv-unsupported-architecture:
  test.fail_without_changes:
    - name: "uv supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}
{% set asset = 'uv-' ~ target ~ '.tar.gz' %}
{% set download_url = uv.base_url ~ '/' ~ uv.version ~ '/' ~ asset %}
{% set version_dir = uv.install_dir ~ '/versions/' ~ uv.version %}
uv-archive:
  archive.extracted:
    - name: {{ version_dir }}
    - source: {{ download_url }}
    # Upstream publishes a per-asset .sha256 file next to each archive.
    - source_hash: {{ download_url }}.sha256
    - user: root
    - group: root
    - archive_format: tar
    # Archive contains a top-level uv-<target>/ dir; strip it.
    - options: --strip-components=1
    - enforce_toplevel: false
    - unless: ls {{ version_dir }}/uv {{ version_dir }}/uvx
uv-symlink:
  file.symlink:
    - name: {{ uv.bin_dir }}/uv
    - target: {{ version_dir }}/uv
    - force: true
    - require:
      - archive: uv-archive
uv-uvx-symlink:
  file.symlink:
    - name: {{ uv.bin_dir }}/uvx
    - target: {{ version_dir }}/uvx
    - force: true
    - require:
      - archive: uv-archive
{% endif %}
