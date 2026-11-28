# -*- coding: utf-8 -*-
# vim: ft=jinja
{% from tpldir ~ "/map.jinja" import strands with context %}
{% set venv = strands.venv_dir %}
{#- The venv is shared with strands.evals; whichever state runs first creates it #}
strands-harness-venv-pkg:
  pkg.installed:
    - name: python3-venv
strands-harness-venv:
  cmd.run:
    - name: /usr/bin/python3 -m venv {{ venv }}
    - creates: {{ venv }}/bin/python
    - require:
      - pkg: strands-harness-venv-pkg
strands-harness-package:
  pip.installed:
    - name: strands-harness=={{ strands.harness.version }}
    - bin_env: {{ venv }}
    # In test=True the venv is not created yet, so pip.installed would fail.
    - onlyif: test -x {{ venv }}/bin/pip
    - require:
      - cmd: strands-harness-venv
