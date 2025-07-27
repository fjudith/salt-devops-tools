# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import kyverno with context %}

include:
  {%- if kyverno.enabled %}
  - .install
  {%- elif not kyverno.enabled %}
  - .teardown
  {% endif %}