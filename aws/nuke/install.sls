# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import aws_nuke with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
aws-nuke-unsupported-architecture:
  test.fail_without_changes:
    - name: "aws-nuke supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

aws-nuke-archive:
  archive.extracted:
    - name: /usr/local/aws-nuke/{{ aws_nuke.version }}
    - source: https://github.com/rebuy-de/aws-nuke/releases/download/v{{ aws_nuke.version }}/aws-nuke-v{{ aws_nuke.version }}-linux-{{ bin_arch }}.tar.gz
    - skip_verify: true
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    - unless: ls /usr/local/aws-nuke/{{ aws_nuke.version }}

aws-nuke:
  file.symlink:
    - name: /usr/local/bin/aws-nuke
    - target: /usr/local/aws-nuke/{{ aws_nuke.version }}/aws-nuke-v{{ aws_nuke.version }}-linux-{{ bin_arch }}
{% endif %}
