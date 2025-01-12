# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import bom with context %}

include:
  {%- if bom.enabled %}
  - .install
  {%- elif not bom.enabled %}
  - .teardown
  {% endif %}