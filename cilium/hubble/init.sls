# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import hubble with context %}

include:
  {%- if hubble.enabled %}
  - .install
  {%- elif not hubble.enabled %}
  - .teardown
  {% endif %}