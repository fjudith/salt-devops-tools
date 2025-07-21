# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import kind with context %}

include:
  {%- if kind.enabled %}
  - .install
  {%- elif not kind.enabled %}
  - .teardown
  {% endif %}