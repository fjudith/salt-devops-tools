# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import oslo with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'x86_64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
oslo-unsupported-architecture:
  test.fail_without_changes:
    - name: "oslo supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

oslo-archive:
  archive.extracted:
    - name: /usr/local/oslo/{{ oslo.version }}
    - source: https://github.com/OpenSLO/oslo/releases/download/v{{ oslo.version }}/oslo_linux_{{ bin_arch }}.tar.gz
    - source_hash: https://github.com/OpenSLO/oslo/releases/download/v{{ oslo.version }}/oslo_{{ oslo.version }}_checksums.txt
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    # - options: '--strip-components=1'
    - unless: ls /usr/local/oslo/{{ oslo.version }}

oslo:
  file.symlink:
    - name: /usr/local/bin/oslo
    - target: /usr/local/oslo/{{ oslo.version }}/bin/oslo

oslo-completion:
  cmd.run:
    - require:
      - file: oslo
    - name: /usr/local/bin/oslo completion bash | tee /etc/bash_completion.d/oslo
{% endif %}
