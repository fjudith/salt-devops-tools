# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import container_toolkit with context %}

include:
  {%- if container_toolkit.enabled %}
  - .repo
  - .install
  - .config
  {%- else %}
  - .teardown
  {% endif %}
