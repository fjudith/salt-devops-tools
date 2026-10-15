# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import antigravity with context %}

include:
  {%- if antigravity.enabled %}
  - .install
  {%- elif not antigravity.enabled %}
  - .teardown
  {% endif %}
