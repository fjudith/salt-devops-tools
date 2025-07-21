# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import cilium with context %}

include:
  {%- if cilium.enabled %}
  - .install
  {%- elif not cilium.enabled %}
  - .teardown
  {% endif %}