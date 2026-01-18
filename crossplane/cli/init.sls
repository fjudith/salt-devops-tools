# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import crossplane with context %}

include:
  {%- if crossplane.enabled %}
  - .install
  {%- elif not crossplane.enabled %}
  - .teardown
  {% endif %}