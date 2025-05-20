# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import prometheus with context %}

prometheus-archive:
  file.absent:
    - name: /usr/local/prometheus/{{ prometheus.version }}

prometheus:
  file.absent:
    - name: /usr/local/bin/prometheus

promtool:
  file.absent:
    - name: /usr/local/bin/promtool

prometheus-completion:
  file.absent:
    - name: /etc/bash_completion.d/prometheus

promtool-completion:
  file.absent:
    - name: /etc/bash_completion.d/promtool
