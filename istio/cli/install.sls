# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import istio with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
istioctl-unsupported-architecture:
  test.fail_without_changes:
    - name: "istioctl supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

istio-archive:
  archive.extracted:
    - name: /usr/local/istio/{{ istio.version }}
    - source: https://github.com/istio/istio/releases/download/{{ istio.version }}/istioctl-{{ istio.version }}-linux-{{ bin_arch }}.tar.gz
    - source_hash: https://github.com/istio/istio/releases/download/{{ istio.version }}/istioctl-{{ istio.version }}-linux-{{ bin_arch }}.tar.gz.sha256
    - skip_verify: false
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    - unless: ls /usr/local/istio/{{ istio.version }}

istioctl:
  file.symlink:
    - name: /usr/local/bin/istioctl
    - target: /usr/local/istio/{{ istio.version }}/istioctl
{% endif %}
