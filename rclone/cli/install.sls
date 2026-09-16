# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import rclone with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
rclone-unsupported-architecture:
  test.fail_without_changes:
    - name: "rclone supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

rclone:
  {%- if rclone.enabled %}
  pkg.installed:
    - sources:
      {%- if grains['os_family']|lower in ('debian',) %}
      - rclone: https://github.com/rclone/rclone/releases/download/v{{ rclone.version }}/rclone-v{{ rclone.version }}-linux-{{ bin_arch }}.deb
      {%- elif grains['os_family']|lower in ('redhat',) %}
      - rclone: https://github.com/rclone/rclone/releases/download/v{{ rclone.version }}/rclone-v{{ rclone.version }}-linux-{{ bin_arch }}.rpm
      {%- endif %}
  {%- else %}
  pkg.removed:
    - name: rclone
  {%- endif %}
{% endif %}
