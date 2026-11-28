# -*- coding: utf-8 -*-
# vim: ft=jinja
{% from tpldir ~ "/map.jinja" import strands with context %}
include:
  {%- if strands.box.enabled %}
  - .install
  {%- elif not strands.box.enabled %}
  - .teardown
  {% endif %}
