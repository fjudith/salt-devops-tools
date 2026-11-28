# -*- coding: utf-8 -*-
# vim: ft=jinja
{% from tpldir ~ "/map.jinja" import bun with context %}
{#- Detect architecture -> release asset name #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch in ('x86_64', 'amd64') %}
  {#- The default x64 build needs AVX2; fall back to baseline without it. #}
  {% set baseline = bun.variant == 'baseline' or (bun.variant == 'auto' and 'avx2' not in salt['grains.get']('cpu_flags', [])) %}
  {% set target = 'linux-x64' ~ ('-baseline' if baseline else '') %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set target = 'linux-aarch64' %}
{% endif %}
{% if target is not defined %}
bun-unsupported-architecture:
  test.fail_without_changes:
    - name: "bun supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}
{% set asset = 'bun-' ~ target ~ '.zip' %}
{% set release_url = bun.base_url ~ '/bun-v' ~ bun.version %}
{% set version_dir = bun.install_dir ~ '/versions/' ~ bun.version %}
{#- The zip contains a top-level bun-<target>/ dir holding the binary. #}
{% set bun_bin = version_dir ~ '/bun-' ~ target ~ '/bun' %}
bun-archive:
  archive.extracted:
    - name: {{ version_dir }}
    - source: {{ release_url }}/{{ asset }}
    # Checksums for every asset are listed in SHASUMS256.txt.
    - source_hash: {{ release_url }}/SHASUMS256.txt
    - user: root
    - group: root
    - archive_format: zip
    - enforce_toplevel: false
    - unless: ls {{ bun_bin }}
bun-binary-mode:
  file.managed:
    - name: {{ bun_bin }}
    - mode: '0755'
    - replace: false
    - create: false
    - require:
      - archive: bun-archive
bun-symlink:
  file.symlink:
    - name: {{ bun.bin_dir }}/bun
    - target: {{ bun_bin }}
    - force: true
    - require:
      - file: bun-binary-mode
bun-bunx-symlink:
  file.symlink:
    - name: {{ bun.bin_dir }}/bunx
    - target: {{ bun_bin }}
    - force: true
    - require:
      - file: bun-binary-mode
{% endif %}
