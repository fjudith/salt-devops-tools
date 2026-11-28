# -*- coding: utf-8 -*-
# vim: ft=jinja
{#- Not toggled on its own: strands.harness, strands.evals and strands.cli include it.
    The venv is needed while harness or evals is enabled; otherwise it is removed. #}
include:
  {%- if salt['pillar.get']('strands:harness:enabled', false) or salt['pillar.get']('strands:evals:enabled', false) %}
  - .install
  {%- else %}
  - .teardown
  {%- endif %}
