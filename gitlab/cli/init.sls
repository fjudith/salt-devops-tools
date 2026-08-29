# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import glab with context %}

include:
  {%- if glab.enabled %}
  - .install
  {%- elif not glab.enabled %}
  - .teardown
  {% endif %}
