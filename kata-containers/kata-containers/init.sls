# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import kata_containers with context %}

include:
  {%- if kata_containers.enabled %}
  - .install
  - .config
  {%- else %}
  - .teardown
  {% endif %}
