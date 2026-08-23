# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import kirocli with context %}

include:
  {%- if kirocli.enabled %}
  - .install
  {%- elif not kirocli.enabled %}
  - .teardown
  {% endif %}
