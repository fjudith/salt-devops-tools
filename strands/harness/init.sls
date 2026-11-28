# -*- coding: utf-8 -*-
# vim: ft=jinja
{% from tpldir ~ "/map.jinja" import strands with context %}
include:
  {%- if strands.harness.enabled %}
  - .install
  {%- elif not strands.harness.enabled %}
  - .teardown
  {% endif %}
