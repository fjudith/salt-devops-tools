# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import prometheus with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
prometheus-unsupported-architecture:
  test.fail_without_changes:
    - name: "prometheus supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

prometheus-archive:
  archive.extracted:
    - name: /usr/local/prometheus/{{ prometheus.version }}
    - source: https://github.com/prometheus/prometheus/releases/download/v{{ prometheus.version }}/prometheus-{{ prometheus.version }}.linux-{{ bin_arch }}.tar.gz
    - source_hash: https://github.com/prometheus/prometheus/releases/download/v{{ prometheus.version }}/sha256sums.txt
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    - options: '--strip-components=1'
    - unless: ls /usr/local/prometheus/{{ prometheus.version }}

prometheus:
  file.symlink:
    - name: /usr/local/bin/prometheus
    - target: /usr/local/prometheus/{{ prometheus.version }}/prometheus

promtool:
  file.symlink:
    - name: /usr/local/bin/promtool
    - target: /usr/local/prometheus/{{ prometheus.version }}/promtool

prometheus-completion:
  cmd.run:
    - require:
      - file: prometheus
    - name: /usr/local/bin/prometheus completion bash | tee /etc/bash_completion.d/prometheus

promtool-completion:
  cmd.run:
    - require:
      - file: promtool
    - name: /usr/local/bin/promtool completion bash | tee /etc/bash_completion.d/promtool
{% endif %}
