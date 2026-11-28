# -*- coding: utf-8 -*-
# vim: ft=jinja
{% from tpldir ~ "/map.jinja" import strands with context %}
include:
  {%- if strands.evals.enabled %}
  - .install
  {%- elif not strands.evals.enabled %}
  - .teardown
  {% endif %}
