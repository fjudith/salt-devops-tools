# -*- coding: utf-8 -*-
# vim: ft=jinja
{% from tpldir ~ "/map.jinja" import bun with context %}
include:
  {%- if bun.enabled %}
  - .install
  {%- else %}
  - .teardown
  {%- endif %}
