# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import antigravity with context %}

{#- Detect architecture -> release asset platform suffix #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch in ('x86_64', 'amd64') %}
  {% set platform = 'linux_x64' %}
  {% set musl_lib = '/lib/libc.musl-x86_64.so.1' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set platform = 'linux_arm64' %}
  {% set musl_lib = '/lib/libc.musl-aarch64.so.1' %}
{% endif %}

{% if platform is not defined %}
antigravity-unsupported-architecture:
  test.fail_without_changes:
    - name: "antigravity supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

{#- musl builds: append _musl, matching the official installer's detection #}
{% if salt['file.file_exists'](musl_lib) %}
  {% set platform = platform ~ '_musl' %}
{% endif %}

{% set asset = 'agy_cli_' ~ platform ~ '.tar.gz' %}
{% set download_url = antigravity.base_url ~ '/' ~ antigravity.version ~ '/' ~ asset %}
{% set version_dir = antigravity.install_dir ~ '/' ~ antigravity.version %}

antigravity-archive:
  archive.extracted:
    - name: {{ version_dir }}
    - source: {{ download_url }}
    # Renovate bumps `version` but cannot update a pinned checksum, so skip
    # verification to avoid stale-hash failures (same approach as kubernetes.helm).
    - skip_verify: true
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    - unless: ls {{ version_dir }}/antigravity

antigravity-symlink:
  file.symlink:
    - name: {{ antigravity.bin_dir }}/agy
    - target: {{ version_dir }}/antigravity
    - force: true
    - require:
      - archive: antigravity-archive

{%- if antigravity.completion %}
antigravity-completion:
  cmd.run:
    - name: {{ antigravity.bin_dir }}/agy completion bash | tee /etc/bash_completion.d/agy
    - creates: /etc/bash_completion.d/agy
    # best-effort: only run if `agy completion` actually exists (unverified upstream)
    - onlyif: {{ antigravity.bin_dir }}/agy completion bash >/dev/null 2>&1
    - require:
      - file: antigravity-symlink
{%- endif %}

{% endif %}
