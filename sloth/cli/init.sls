# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import sloth with context %}

include:
  {%- if sloth.enabled %}
  - .install
  {%- elif not sloth.enabled %}
  - .teardown
  {% endif %}