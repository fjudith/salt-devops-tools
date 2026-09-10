# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import nerdctl with context %}

include:
  {%- if nerdctl.enabled %}
  - .install
  {%- else %}
  - .teardown
  {% endif %}
