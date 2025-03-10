# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import kubestack with context %}

include:
  {%- if kubestack.enabled %}
  - .install
  {%- elif not kubestack.enabled %}
  - .teardown
  {% endif %}