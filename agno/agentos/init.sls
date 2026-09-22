# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import agno with context %}

include:
  {%- if agno.agentos.enabled %}
  - .install
  {%- elif not agno.agentos.enabled %}
  - .teardown
  {% endif %}
