# -*- coding: utf-8 -*-
# vim: ft=jinja
{% from tpldir ~ "/map.jinja" import aidlc with context %}
include:
  {%- if aidlc.enabled %}
  - .install
  {%- elif not aidlc.enabled %}
  - .teardown
  {% endif %}
