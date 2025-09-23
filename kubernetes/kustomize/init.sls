# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import kustomize with context %}

include:
  {%- if kustomize.enabled %}
  - .install
  {%- elif not kustomize.enabled %}
  - .teardown
  {% endif %}