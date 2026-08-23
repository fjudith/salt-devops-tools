# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import agentgateway with context %}

include:
  {%- if agentgateway.enabled %}
  - .install
  - .config
  - .aws-iam-roles-anywhere
  {%- elif not agentgateway.enabled %}
  - .teardown
  {% endif %}
