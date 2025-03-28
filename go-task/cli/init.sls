# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import gotask with context %}

include:
  {%- if gotask.enabled %}
  - .install
  {%- elif not gotask.enabled %}
  - .teardown
  {% endif %}