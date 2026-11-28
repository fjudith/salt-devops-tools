# -*- coding: utf-8 -*-
# vim: ft=jinja
{% from tpldir ~ "/map.jinja" import aidlc with context %}
{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch in ('x86_64', 'amd64') %}
  {% set aidlc_arch = 'x64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set aidlc_arch = 'arm64' %}
{% endif %}
{% if aidlc_arch is not defined %}
aidlc-unsupported-architecture:
  test.fail_without_changes:
    - name: "aidlc supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}
{#- musl build on Alpine #}
{% set musl = salt['grains.get']('os_family') == 'Alpine' %}
{% set binary = 'aidlc-linux-' ~ aidlc_arch ~ ('-musl' if musl else '') %}
{% set runtime = 'aidlc-runtime-' ~ aidlc.version ~ '.tar.gz' %}
{#- Versioned URL: a version bump changes the URL, so Salt's download cache is not reused #}
{% set release_url = aidlc.base_url ~ '/v' ~ aidlc.version %}
{% set version_dir = aidlc.install_dir ~ '/versions/' ~ aidlc.version %}
{% if musl %}
aidlc-dependencies:
  pkg.installed:
    - pkgs:
      - libgcc
      - libstdc++
    - require_in:
      - file: aidlc-symlink
{% endif %}
{#- Extract first: the tarball holds plugins/ and runtime/ only, the binary is placed after #}
aidlc-runtime:
  archive.extracted:
    - name: {{ version_dir }}
    - source: {{ release_url }}/{{ runtime }}
    - source_hash: {{ release_url }}/checksums.txt
    - source_hash_name: {{ runtime }}
    - user: root
    - group: root
    - archive_format: tar
    # The tarball has two top-level dirs (plugins/, runtime/).
    - enforce_toplevel: false
    - unless: test -d {{ version_dir }}/runtime -a -d {{ version_dir }}/plugins
aidlc-binary:
  file.managed:
    - name: {{ version_dir }}/aidlc
    - source: {{ release_url }}/{{ binary }}
    - source_hash: {{ release_url }}/checksums.txt
    - source_hash_name: {{ binary }}
    - user: root
    - group: root
    - mode: '0755'
    - makedirs: true
    - require:
      - archive: aidlc-runtime
aidlc-symlink:
  file.symlink:
    - name: {{ aidlc.bin_dir }}/aidlc
    - target: {{ version_dir }}/aidlc
    - force: true
    - require:
      - file: aidlc-binary
{% endif %}
