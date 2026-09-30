# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import containerd with context %}

include:
  {%- if containerd.enabled %}
  - .install
  {%- else %}
  - .teardown
  {% endif %}
