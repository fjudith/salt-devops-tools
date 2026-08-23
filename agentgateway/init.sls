# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import agentgateway with context %}

include:
  {%- if agentgateway.enabled %}
  - .install
  - .config
  {%- elif not agentgateway.enabled %}
  - .teardown
  {% endif %}
