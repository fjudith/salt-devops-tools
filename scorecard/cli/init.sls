# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import scorecard with context %}

include:
  {%- if scorecard.enabled %}
  - .install
  {%- elif not scorecard.enabled %}
  - .teardown
  {% endif %}