# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import helm with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
helm-unsupported-architecture:
  test.fail_without_changes:
    - name: "helm supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

helm-archive:
  archive.extracted:
    - name: /usr/local/helm/{{ helm.version }}
    - source: https://get.helm.sh/helm-v{{ helm.version }}-linux-{{ bin_arch }}.tar.gz
    - source_hash: https://get.helm.sh/helm-v{{ helm.version }}-linux-{{ bin_arch }}.tar.gz.sha256sum
    - skip_verify: true
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    - options: '--strip-components=1'
    - unless: ls /usr/local/helm/{{ helm.version }}

helm:
  file.symlink:
    - name: /usr/local/bin/helm
    - target: /usr/local/helm/{{ helm.version }}/helm
{% endif %}
