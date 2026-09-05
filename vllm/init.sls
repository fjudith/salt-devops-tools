# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import vllm with context %}

include:
  {%- if vllm.enabled %}
  - .install
  {%- else %}
  - .teardown
  {% endif %}
