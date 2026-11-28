# -*- coding: utf-8 -*-
# vim: ft=jinja
{% from tpldir ~ "/map.jinja" import strands with context %}
{#- The venv is shared by strands.harness and strands.evals #}
strands-common-venv-pkg:
  pkg.installed:
    - name: python3-venv
strands-common-venv:
  cmd.run:
    - name: /usr/bin/python3 -m venv {{ strands.venv_dir }}
    - creates: {{ strands.venv_dir }}/bin/python
    - require:
      - pkg: strands-common-venv-pkg
