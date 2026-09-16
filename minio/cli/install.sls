# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import mcli with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
mcli-unsupported-architecture:
  test.fail_without_changes:
    - name: "mcli supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

mcli:
  {%- if mcli.enabled %}
  pkg.installed:
    - sources:
      {%- if grains['os_family']|lower in ('debian',) %}
      - mcli: https://dl.min.io/client/mc/release/linux-{{ bin_arch }}/mcli_{{ mcli.version }}_{{ bin_arch }}.deb
      {%- elif grains['os_family']|lower in ('redhat',) %}
      - mcli: https://dl.min.io/client/mc/release/linux-{{ bin_arch }}/mcli-{{ mcli.version }}.{{ 'x86_64' if bin_arch == 'amd64' else 'aarch64' }}.rpm
      {%- endif %}
  {%- else %}
  pkg.removed:
    - name: mccli
  {%- endif %}
{% endif %}
