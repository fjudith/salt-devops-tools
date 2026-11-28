# -*- coding: utf-8 -*-
# vim: ft=jinja
{% from tpldir ~ "/map.jinja" import uv with context %}
include:
  {%- if uv.enabled %}
  - .install
  {%- else %}
  - .teardown
  {%- endif %}
