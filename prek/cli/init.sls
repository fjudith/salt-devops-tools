# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import prek with context %}

include:
  {%- if prek.enabled %}
  - .install
  {%- elif not prek.enabled %}
  - .teardown
  {% endif %}
