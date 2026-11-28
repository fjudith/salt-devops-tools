# -*- coding: utf-8 -*-
# vim: ft=jinja
{% from tpldir ~ "/map.jinja" import strands with context %}
{% set venv = strands.venv_dir %}
include:
  - strands.common
strands-harness-teardown-package:
  cmd.run:
    - name: {{ venv }}/bin/pip uninstall -y strands-harness
    - onlyif: {{ venv }}/bin/pip show strands-harness
