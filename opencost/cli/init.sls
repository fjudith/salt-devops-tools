# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import opencost with context %}

include:
  {%- if opencost.enabled %}
  - .install
  {%- elif not opencost.enabled %}
  - .teardown
  {% endif %}