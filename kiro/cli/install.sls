# -*- coding: utf-8 -*-
# vim: ft=jinja
{% from tpldir ~ "/map.jinja" import kirocli with context %}
{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch in ('x86_64', 'amd64') %}
  {% set kiro_arch = 'x86_64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set kiro_arch = 'aarch64' %}
{% endif %}
{% if kiro_arch is not defined %}
kirocli-unsupported-architecture:
  test.fail_without_changes:
    - name: "kiro-cli supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}
{#- Determine libc variant (musl vs gnu) #}
{% set libc = 'musl' if salt['grains.get']('os_family') == 'Alpine' else 'gnu' %}
{% set filename = 'kirocli-' ~ kiro_arch ~ '-linux' ~ ('-musl' if libc == 'musl' else '') ~ '.zip' %}
{#- Versioned URL: a version bump changes the URL, so Salt's download cache is not reused #}
{% set download_url = kirocli.base_url ~ '/' ~ kirocli.channel ~ '/' ~ kirocli.version ~ '/' ~ filename %}
{% set version_dir = kirocli.install_dir ~ '/versions/' ~ kirocli.version %}
{% set sha256 = kirocli.get('sha256', {}).get(kiro_arch ~ '-' ~ libc) %}
kirocli-dependencies:
  pkg.installed:
    - pkgs:
      - unzip
kirocli-archive:
  archive.extracted:
    - name: {{ version_dir }}
    - source: {{ download_url }}
    {%- if sha256 %}
    - source_hash: sha256={{ sha256 }}
    {%- else %}
    - skip_verify: true
    {%- endif %}
    - user: root
    - group: root
    - archive_format: zip
    - enforce_toplevel: false
    - require:
      - pkg: kirocli-dependencies
    - unless: test -x {{ version_dir }}/kirocli/bin/kiro-cli
kirocli-symlink:
  file.symlink:
    - name: {{ kirocli.bin_dir }}/kiro-cli
    - target: {{ version_dir }}/kirocli/bin/kiro-cli
    - force: true
    - require:
      - archive: kirocli-archive
{#- Legacy 2.x artifacts: kiro-cli-chat/-term no longer exist in 3.x, and the old
    flat layout lived directly under install_dir/kirocli #}
kirocli-legacy-chat-symlink:
  file.absent:
    - name: {{ kirocli.bin_dir }}/kiro-cli-chat
    - require:
      - file: kirocli-symlink
kirocli-legacy-term-symlink:
  file.absent:
    - name: {{ kirocli.bin_dir }}/kiro-cli-term
    - require:
      - file: kirocli-symlink
kirocli-legacy-install-dir:
  file.absent:
    - name: {{ kirocli.install_dir }}/kirocli
    - require:
      - file: kirocli-symlink
{% endif %}
