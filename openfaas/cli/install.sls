# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import openfaas with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = '' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = '-arm64' %}
{% endif %}

{% if bin_arch is not defined %}
faas-cli-unsupported-architecture:
  test.fail_without_changes:
    - name: "faas-cli supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

openfaas-binary:
  file.managed:
    - name: /usr/local/openfaas/{{ openfaas.version }}/faas-cli{{ bin_arch }}
    - source: https://github.com/openfaas/faas-cli/releases/download/{{ openfaas.version }}/faas-cli{{ bin_arch }}
    - source_hash: https://github.com/openfaas/faas-cli/releases/download/{{ openfaas.version }}/faas-cli{{ bin_arch }}.sha256
    - makedirs: true
    - user: root
    - group: root
    - mode: '0755'
    - unless: ls /usr/local/openfaas/{{ openfaas.version }}

openfaas:
  file.symlink:
    - name: /usr/local/bin/faas-cli{{ bin_arch }}
    - target: /usr/local/openfaas/{{ openfaas.version }}/faas-cli{{ bin_arch }}
    - mode: '0755'
{% endif %}
