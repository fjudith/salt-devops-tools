# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import terraform_docs with context %}

include:
  {%- if terraform_docs.enabled %}
  - .install
  {%- elif not terraform_docs.enabled %}
  - .teardown
  {% endif %}