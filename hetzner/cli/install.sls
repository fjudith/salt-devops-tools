# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import hcloud with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
hcloud-unsupported-architecture:
  test.fail_without_changes:
    - name: "hcloud supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

hcloud-archive:
  archive.extracted:
    - name: /usr/local/hetzner/{{ hcloud.version }}
    - source: https://github.com/hetznercloud/cli/releases/download/v{{ hcloud.version }}/hcloud-linux-{{ bin_arch }}.tar.gz
    - source_hash: https://github.com/hetznercloud/cli/releases/download/v{{ hcloud.version }}/checksums.txt
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    # - options: '--strip-components=1'
    - unless: ls /usr/local/hetzner/{{ hcloud.version }}

hcloud:
  file.symlink:
    - name: /usr/local/bin/hcloud
    - target: /usr/local/hetzner/{{ hcloud.version }}/hcloud
{% endif %}
