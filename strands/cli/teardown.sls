# -*- coding: utf-8 -*-
# vim: ft=jinja
{% from tpldir ~ "/map.jinja" import strands with context %}
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

{#- The venv belongs to strands.harness / strands.evals; keep the root while either is enabled #}
{%- if not (salt['pillar.get']('strands:harness:enabled', false) or salt['pillar.get']('strands:evals:enabled', false)) %}
strands-cli-teardown-root:
  file.absent:
    - name: {{ strands.root_dir }}
    - onlyif: test -z "$(ls -A {{ strands.root_dir }} 2>/dev/null | grep -Ev '^(cli|node)$')"
    - require:
      - file: strands-cli-teardown-cli
      - file: strands-cli-teardown-node
{%- endif %}
