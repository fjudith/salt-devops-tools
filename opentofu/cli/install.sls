# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import opentofu with context %}

{% set pkgState = 'removed' %}
{% if opentofu.enabled %}
  {% set pkgState = 'installed' %}
{% endif %}

tofu:
  pkg.{{ pkgState }}:
    - version: {{ opentofu.version }}
    {%- if opentofu.enabled and grains['os_family']|lower in ('debian', 'redhat') %}
    - require:
      - pkgrepo: opentofu-repo
    {%- endif %}
