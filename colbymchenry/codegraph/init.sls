# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import codegraph with context %}

include:
  {%- if codegraph.enabled %}
  - .install
  {%- elif not codegraph.enabled %}
  - .teardown
  {% endif %}
