# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import oslo with context %}

include:
  {%- if oslo.enabled %}
  - .install
  {%- elif not oslo.enabled %}
  - .teardown
  {% endif %}