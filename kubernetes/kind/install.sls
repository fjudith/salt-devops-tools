# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import kind with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
kind-unsupported-architecture:
  test.fail_without_changes:
    - name: "kind supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

kind-binary:
  file.managed:
    - name: /usr/local/kind/{{ kind.version }}/kind
    - source: https://github.com/kubernetes-sigs/kind/releases/download/v{{ kind.version }}/kind-linux-{{ bin_arch }}
    - source_hash: https://github.com/kubernetes-sigs/kind/releases/download/v{{ kind.version}}/kind-linux-{{ bin_arch }}.sha256sum
    - makedirs: true
    - user: root
    - group: root
    - mode: '0755'
    - unless: ls /usr/local/kind/{{ kind.version }}

kind:
  file.symlink:
    - name: /usr/local/bin/kind
    - target: /usr/local/kind/{{ kind.version }}/kind
    - mode: '0755'
{% endif %}
