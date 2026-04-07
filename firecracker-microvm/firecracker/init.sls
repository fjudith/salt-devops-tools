# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import firecracker with context %}

include:
  {%- if firecracker.enabled %}
  - .install
  {%- elif not firecracker.enabled %}
  - .teardown
  {% endif %}