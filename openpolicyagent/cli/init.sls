# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import opa with context %}

include:
  {%- if opa.enabled %}
  - .install
  {%- elif not opa.enabled %}
  - .teardown
  {% endif %}