# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import nvm with context %}

include:
  {%- if nvm.enabled %}
  - .install
  {%- elif not nvm.enabled %}
  - .teardown
  {% endif %}
