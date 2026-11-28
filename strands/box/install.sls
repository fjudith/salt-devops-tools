# -*- coding: utf-8 -*-
# vim: ft=jinja
{% from tpldir ~ "/map.jinja" import strands with context %}
{% set b = strands.box %}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch in ('x86_64', 'amd64') %}
  {% set target = 'x86_64-unknown-linux-gnu' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set target = 'aarch64-unknown-linux-gnu' %}
{% endif %}
{% if target is not defined %}
strands-box-unsupported-architecture:
  test.fail_without_changes:
    - name: "strands box supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}
{% set asset = 'box-cli-v' ~ b.version ~ '-' ~ target ~ '.tar.gz' %}
{% set release_url = b.base_url ~ '/v' ~ b.version %}
{% set version_dir = b.install_dir ~ '/versions/' ~ b.version %}
strands-box-archive:
  archive.extracted:
    - name: {{ version_dir }}
    - source: {{ release_url }}/{{ asset }}
    - source_hash: {{ release_url }}/SHA256SUMS.txt
    - source_hash_name: {{ asset }}
    - user: root
    - group: root
    - archive_format: tar
    # The tarball is flat (no top-level directory).
    - enforce_toplevel: false
    - unless: test -x {{ version_dir }}/box

strands-box-current:
  file.symlink:
    - name: {{ b.install_dir }}/current
    - target: {{ version_dir }}
    - force: true
    - require:
      - archive: strands-box-archive

strands-box-symlink:
  file.symlink:
    - name: {{ b.bin_dir }}/box
    - target: {{ b.install_dir }}/current/box
    - force: true
    - require:
      - file: strands-box-current
{% endif %}
