# -*- coding: utf-8 -*-
# vim: ft=jinja
{% from tpldir ~ "/map.jinja" import strands with context %}
{% set venv = strands.venv_dir %}
include:
  - strands.common
strands-harness-package:
  pip.installed:
    - name: strands-harness=={{ strands.harness.version }}
    - bin_env: {{ venv }}
    # In test=True the venv is not created yet, so pip.installed would fail.
    - onlyif: test -x {{ venv }}/bin/pip
    - require:
      - cmd: strands-common-venv
