# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import prometheus with context %}

prometheus-archive:
  archive.extracted:
    - name: /usr/local/prometheus/{{ prometheus.version }}
    - source: https://github.com/prometheus/prometheus/releases/download/v{{ prometheus.version }}/prometheus-{{ prometheus.version }}.linux-amd64.tar.gz
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