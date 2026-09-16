# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import argo with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
argo-unsupported-architecture:
  test.fail_without_changes:
    - name: "argo supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

argo-archive:
  file.managed:
    - name: /usr/local/argo/{{ argo.version }}/argo-linux-{{ bin_arch }}.gz
    - source: https://github.com/argoproj/argo-workflows/releases/download/v{{ argo.version }}/argo-linux-{{ bin_arch }}.gz
    - source_hash: https://github.com/argoproj/argo-workflows/releases/download/v{{ argo.version }}/argo-workflows-cli-checksums.txt
    - makedirs: True
    - user: root
    - group: root
    - unless: ls /usr/local/argo/{{ argo.version }}
  module.run:
    - name: archive.gunzip
    - gzipfile: /usr/local/argo/{{ argo.version }}/argo-linux-{{ bin_arch }}.gz
    - options: '--quiet'
    - unless: ls /usr/local/argo/{{ argo.version }}/argo-linux-{{ bin_arch }}

argo-permissions:
  file.managed:
    - name: /usr/local/argo/{{ argo.version }}/argo-linux-{{ bin_arch }}
    - user: root
    - group: root
    - mode: 755

argo:
  file.symlink:
    - name: /usr/local/bin/argo
    - target: /usr/local/argo/{{ argo.version }}/argo-linux-{{ bin_arch }}
{% endif %}
