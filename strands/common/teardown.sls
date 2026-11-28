# -*- coding: utf-8 -*-
# vim: ft=jinja
{% from tpldir ~ "/map.jinja" import strands with context %}
{#- Rendered only when harness and evals are both off: remove the venv (clears orphaned dependencies) #}
strands-common-teardown-venv:
  file.absent:
    - name: {{ strands.venv_dir }}
{#- The root holds cli and node while strands.cli is enabled; remove it only when harness, evals and cli are all off #}
{%- if not salt['pillar.get']('strands:cli:enabled', false) %}
strands-common-teardown-root:
  file.absent:
    - name: {{ strands.root_dir }}
    - onlyif: test -z "$(ls -A {{ strands.root_dir }} 2>/dev/null | grep -Ev '^(cli|node|{{ strands.venv_dir.split('/')[-1] }})$')"
    - require:
      - file: strands-common-teardown-venv
{%- endif %}
