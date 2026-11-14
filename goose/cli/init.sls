# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import goose with context %}

include:
  {%- if goose.enabled %}
  - .install
  {%- elif not goose.enabled %}
  - .teardown
  {% endif %}
