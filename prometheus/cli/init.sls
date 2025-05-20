# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import prometheus with context %}

include:
  {%- if prometheus.enabled %}
  - .install
  {%- elif not prometheus.enabled %}
  - .teardown
  {% endif %}