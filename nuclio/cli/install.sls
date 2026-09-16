# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import nuctl with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
nuctl-unsupported-architecture:
  test.fail_without_changes:
    - name: "nuctl supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

nuctl-binary:
  file.managed:
    - name: /usr/local/nuclio/{{ nuctl.version }}/nuctl-linux-{{ bin_arch }}
    - source: https://github.com/nuclio/nuclio/releases/download/{{ nuctl.version }}/nuctl-{{ nuctl.version }}-linux-{{ bin_arch }}
    - skip_verify: true
    - makedirs: true
    - user: root
    - group: root
    - mode: 755
    - unless: ls /usr/local/nuclio/{{ nuctl.version }}

nuctl:
  file.symlink:
    - name: /usr/local/bin/nuctl
    - target: /usr/local/nuclio/{{ nuctl.version }}/nuctl-linux-{{ bin_arch }}
    - mode: 755
{% endif %}
