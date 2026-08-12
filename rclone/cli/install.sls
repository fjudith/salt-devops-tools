# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import rclone with context %}

rclone:
  {%- if rclone.enabled %}
  pkg.installed:
    - sources:
      {%- if grains['os_family']|lower in ('debian',) %}
      - rclone: https://github.com/rclone/rclone/releases/download/v{{ rclone.version }}/rclone-v{{ rclone.version }}-linux-amd64.deb
      {%- elif grains['os_family']|lower in ('redhat',) %}
      - rclone: https://github.com/rclone/rclone/releases/download/v{{ rclone.version }}/rclone-v{{ rclone.version }}-linux-amd64.rpm
      {%- endif %}
  {%- else %}
  pkg.removed:
    - name: rclone
  {%- endif %}