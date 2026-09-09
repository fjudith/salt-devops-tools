# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import cloud_hypervisor with context %}

include:
  {%- if cloud_hypervisor.enabled %}
  - .install
  {%- else %}
  - .teardown
  {% endif %}
