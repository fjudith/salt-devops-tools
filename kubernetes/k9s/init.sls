# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import k9s with context %}

include:
  {%- if k9s.enabled %}
  - .install
  {%- elif not k9s.enabled %}
  - .teardown
  {% endif %}