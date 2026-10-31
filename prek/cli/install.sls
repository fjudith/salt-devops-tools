# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import prek with context %}

{#- Detect architecture -> release asset target triple #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch in ('x86_64', 'amd64') %}
  {% set target = 'x86_64-unknown-linux-gnu' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set target = 'aarch64-unknown-linux-gnu' %}
{% endif %}

{% if target is not defined %}
prek-unsupported-architecture:
  test.fail_without_changes:
    - name: "prek supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

{% set asset = 'prek-' ~ target ~ '.tar.gz' %}
{% set download_url = prek.base_url ~ '/v' ~ prek.version ~ '/' ~ asset %}
{% set version_dir = prek.install_dir ~ '/' ~ prek.version %}

prek-archive:
  archive.extracted:
    - name: {{ version_dir }}
    - source: {{ download_url }}
    # Each release publishes a per-asset .sha256 file, so the checksum follows
    # Renovate version bumps without a pinned hash.
    - source_hash: {{ download_url }}.sha256
    - user: root
    - group: root
    - archive_format: tar
    # Archive contains a top-level prek-<target>/ dir; strip it.
    - options: --strip-components=1
    - enforce_toplevel: false
    - unless: ls {{ version_dir }}/prek

prek-symlink:
  file.symlink:
    - name: {{ prek.bin_dir }}/prek
    - target: {{ version_dir }}/prek
    - force: true
    - require:
      - archive: prek-archive

{%- if prek.completion %}
prek-completion:
  cmd.run:
    - name: {{ prek.bin_dir }}/prek util generate-shell-completion bash > /etc/bash_completion.d/prek
    - onchanges:
      - file: prek-symlink
    - require:
      - file: prek-symlink
{%- endif %}

{% endif %}
