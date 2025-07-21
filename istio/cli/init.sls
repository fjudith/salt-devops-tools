# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import istio with context %}

include:
  {%- if istio.enabled %}
  - .install
  {%- elif not istio.enabled %}
  - .teardown
  {% endif %}