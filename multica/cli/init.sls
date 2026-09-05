# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import multica with context %}

include:
  {%- if multica.enabled %}
  - .install
  - .config
  {%- elif not multica.enabled %}
  - .teardown
  {% endif %}