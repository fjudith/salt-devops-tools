# -*- coding: utf-8 -*-
# vim: ft=jinja
{% from tpldir ~ "/map.jinja" import strands with context %}
{% set venv = strands.venv_dir %}
{% set other_enabled = salt['pillar.get']('strands:harness:enabled', false) %}
{% set cli_enabled = salt['pillar.get']('strands:cli:enabled', false) %}
strands-evals-teardown-package:
  cmd.run:
    - name: {{ venv }}/bin/pip uninstall -y strands-agents-evals
    - onlyif: {{ venv }}/bin/pip show strands-agents-evals
{%- if not other_enabled %}
{#- Both harness and evals are off: remove the whole venv (clears orphaned dependencies) #}
strands-evals-teardown-venv:
  file.absent:
    - name: {{ venv }}
    - require:
      - cmd: strands-evals-teardown-package
{%- if not cli_enabled %}
strands-evals-teardown-root:
  file.absent:
    - name: {{ strands.root_dir }}
    - onlyif: test -z "$(ls -A {{ strands.root_dir }} 2>/dev/null)"
    - require:
      - file: strands-evals-teardown-venv
{%- endif %}
{%- endif %}
