# -*- coding: utf-8 -*-
# vim: ft=jinja
{% from tpldir ~ "/map.jinja" import strands with context %}
include:
  - strands.common
{% set c = strands.cli %}
strands-cli-teardown-wrapper:
  file.absent:
    - name: {{ c.bin_dir }}/strands

strands-cli-teardown-cli:
  file.absent:
    - name: {{ strands.root_dir }}/cli

strands-cli-teardown-node:
  file.absent:
    - name: {{ strands.root_dir }}/node
