# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import terragrunt with context %}

include:
  {%- if terragrunt.enabled %}
  - .install
  {%- elif not terragrunt.enabled %}
  - .teardown
  {% endif %}