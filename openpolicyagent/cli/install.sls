# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import opa with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
opa-unsupported-architecture:
  test.fail_without_changes:
    - name: "opa supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

opa-binary:
  file.managed:
    - name: /usr/local/open-policy-agent/{{ opa.version }}/opa
    - source: https://github.com/open-policy-agent/opa/releases/download/v{{ opa.version }}/opa_linux_{{ bin_arch }}
    - source_hash: https://github.com/open-policy-agent/opa/releases/download/v{{ opa.version }}/opa_linux_{{ bin_arch }}.sha256
    - makedirs: true
    - user: root
    - group: root
    - mode: '0755'
    - unless: ls /usr/local/open-policy-agent/{{ opa.version }}

opa:
  file.symlink:
    - name: /usr/local/bin/opa
    - target: /usr/local/open-policy-agent/{{ opa.version }}/opa
    - mode: '0755'
{% endif %}
