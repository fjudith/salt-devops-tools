# -*- coding: utf-8 -*-
# vim: ft=jinja
{% from tpldir ~ "/map.jinja" import strands with context %}
{% set venv = strands.venv_dir %}
include:
  - strands.common
strands-evals-package:
  pip.installed:
    - name: strands-agents-evals=={{ strands.evals.version }}
    - bin_env: {{ venv }}
    # In test=True the venv is not created yet, so pip.installed would fail.
    - onlyif: test -x {{ venv }}/bin/pip
    - require:
      - cmd: strands-common-venv
