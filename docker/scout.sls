# -*- coding: utf-8 -*-
# vim: ft=jinja
{%- from tpldir ~ "/map.jinja" import docker with context %}
{%- set scout = docker.scout_plugin %}
{%- if scout.enabled %}
{#- Detect architecture -> release asset arch suffix #}
{%- set arch = salt['grains.get']('cpuarch') %}
{%- if arch in ('x86_64', 'amd64') %}
  {%- set target = 'amd64' %}
{%- elif arch in ('aarch64', 'arm64') %}
  {%- set target = 'arm64' %}
{%- endif %}
{%- if target is not defined %}
docker-scout-unsupported-architecture:
  test.fail_without_changes:
    - name: "docker-scout supports x86_64 and aarch64 only (detected: {{ arch }})"
{%- else %}
{%- set version_num = scout.version | replace('v', '', 1) %}
{%- set asset = 'docker-scout_' ~ version_num ~ '_linux_' ~ target ~ '.tar.gz' %}
{%- set download_url = scout.base_url ~ '/' ~ scout.version ~ '/' ~ asset %}
{%- set version_dir = scout.install_dir ~ '/versions/' ~ scout.version %}
# No hard require on docker-ce-cli: it does not exist in the state tree when
# docker.cli.enabled is false (pkg.removed still defines it, but the plugin is
# just a file and works whenever the CLI is present).
docker-scout-archive:
  archive.extracted:
    - name: {{ version_dir }}
    - source: {{ download_url }}
    # Renovate bumps `version` but cannot update a pinned checksum, so skip
    # verification to avoid stale-hash failures (same approach as codegraph.cli).
    - skip_verify: true
    - user: root
    - group: root
    - archive_format: tar
    # Archive is flat (docker-scout + README.md, no top-level dir).
    - enforce_toplevel: false
    - unless: ls {{ version_dir }}/docker-scout
docker-scout-plugin-dir:
  file.directory:
    - name: {{ scout.plugin_dir }}
    - user: root
    - group: root
    - mode: '0755'
    - makedirs: true
docker-scout-plugin-symlink:
  file.symlink:
    - name: {{ scout.plugin_dir }}/docker-scout
    - target: {{ version_dir }}/docker-scout
    - force: true
    - require:
      - archive: docker-scout-archive
      - file: docker-scout-plugin-dir
{%- endif %}
{%- else %}
docker-scout-plugin-absent:
  file.absent:
    - name: {{ scout.plugin_dir }}/docker-scout
docker-scout-install-absent:
  file.absent:
    - name: {{ scout.install_dir }}
{%- endif %}
