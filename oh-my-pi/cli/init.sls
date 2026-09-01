# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import omp with context %}

include:
  {%- if omp.enabled %}
  - .install
  {%- elif not omp.enabled %}
  - .teardown
  {% endif %}
