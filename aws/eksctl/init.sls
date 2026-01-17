# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import eksctl with context %}

include:
  {%- if eksctl.enabled %}
  - .install
  {%- elif not eksctl.enabled %}
  - .teardown
  {% endif %}