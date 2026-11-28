# -*- coding: utf-8 -*-
# vim: ft=jinja
{% from tpldir ~ "/map.jinja" import strands with context %}
include:
  {%- if strands.cli.enabled %}
  - .install
  {%- elif not strands.cli.enabled %}
  - .teardown
  {% endif %}
