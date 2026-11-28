# -*- coding: utf-8 -*-
# vim: ft=jinja
{% from tpldir ~ "/map.jinja" import strands with context %}
{% set venv = strands.venv_dir %}
{#- The venv is shared with strands.harness; whichever state runs first creates it #}
strands-evals-venv-pkg:
  pkg.installed:
    - name: python3-venv
strands-evals-venv:
  cmd.run:
    - name: /usr/bin/python3 -m venv {{ venv }}
    - creates: {{ venv }}/bin/python
    - require:
      - pkg: strands-evals-venv-pkg
strands-evals-package:
  pip.installed:
    - name: strands-agents-evals=={{ strands.evals.version }}
    - bin_env: {{ venv }}
    # In test=True the venv is not created yet, so pip.installed would fail.
    - onlyif: test -x {{ venv }}/bin/pip
    - require:
      - cmd: strands-evals-venv
