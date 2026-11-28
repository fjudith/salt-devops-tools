# -*- coding: utf-8 -*-
# vim: ft=jinja
{% from tpldir ~ "/map.jinja" import strands with context %}
{% set venv = strands.venv_dir %}
{% set other_enabled = salt['pillar.get']('strands:evals:enabled', false) %}
{% set cli_enabled = salt['pillar.get']('strands:cli:enabled', false) %}
strands-harness-teardown-package:
  cmd.run:
    - name: {{ venv }}/bin/pip uninstall -y strands-harness
    - onlyif: {{ venv }}/bin/pip show strands-harness
{%- if not other_enabled %}
{#- Both harness and evals are off: remove the whole venv (clears orphaned dependencies) #}
strands-harness-teardown-venv:
  file.absent:
    - name: {{ venv }}
    - require:
      - cmd: strands-harness-teardown-package
{%- if not cli_enabled %}
strands-harness-teardown-root:
  file.absent:
    - name: {{ strands.root_dir }}
    - onlyif: test -z "$(ls -A {{ strands.root_dir }} 2>/dev/null)"
    - require:
      - file: strands-harness-teardown-venv
{%- endif %}
{%- endif %}
