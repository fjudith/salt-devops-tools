# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import githubcopilot with context %}

include:
  {%- if githubcopilot.enabled %}
  - .install
  {%- elif not githubcopilot.enabled %}
  - .teardown
  {% endif %}
