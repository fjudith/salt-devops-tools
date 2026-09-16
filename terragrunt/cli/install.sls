# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import terragrunt with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
terragrunt-unsupported-architecture:
  test.fail_without_changes:
    - name: "terragrunt supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

terragrunt-archive:
  archive.extracted:
    - name: /usr/local/terragrunt/{{ terragrunt.version }}
    - source: https://github.com/gruntwork-io/terragrunt/releases/download/v{{ terragrunt.version }}/terragrunt_linux_{{ bin_arch }}.tar.gz
    - source_hash: https://github.com/gruntwork-io/terragrunt/releases/download/v{{ terragrunt.version }}/SHA256SUMS
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    # - options: '--strip-components=1'
    - unless: ls /usr/local/terragrunt/{{ terragrunt.version }}

terragrunt:
  file.symlink:
    - name: /usr/local/bin/terragrunt
    - target: /usr/local/terragrunt/{{ terragrunt.version }}/terragrunt_linux_{{ bin_arch }}
    - mode: 0755
{% endif %}
