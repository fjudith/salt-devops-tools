# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import awscliv2 with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'x86_64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'aarch64' %}
{% endif %}

{% if bin_arch is not defined %}
awscliv2-unsupported-architecture:
  test.fail_without_changes:
    - name: "awscliv2 supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

awscliv2:
  archive.extracted:
    - name: /tmp/awscli
    - source: https://awscli.amazonaws.com/awscli-exe-linux-{{ bin_arch }}-{{ awscliv2.version }}.zip
    - skip_verify: true
    - user: root
    - group: root
    - archive_format: zip
    - enforce_toplevel: false
    - unless: ls /usr/local/aws-cli/v2/{{ awscliv2.version }}
  cmd.run:
    - cwd: /tmp/awscli
    - name: |
        ./aws/install --update
    - runas: root
    - unless: cmp -s /usr/local/aws-cli/v2/current/bin/aws /tmp/awscli/aws/dist/aws
  file.absent:
    - name: /tmp/awscli
{% endif %}
