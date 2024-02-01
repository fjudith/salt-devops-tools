# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import pixie with context %}

include:
  {%- if pixie.enabled %}
  - .install
  {%- elif not pixie.enabled %}
  - .teardown
  {% endif %}