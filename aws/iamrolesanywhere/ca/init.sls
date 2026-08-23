# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import ira with context %}

include:
  {%- if ira.enabled %}
  - .install
  - .signing-helper
  {%- elif not ira.enabled %}
  - .teardown
  {% endif %}
