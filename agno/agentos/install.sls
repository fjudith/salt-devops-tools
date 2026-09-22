# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import agno with context %}

{#- Build the pip requirement: agno[extra1,extra2]==version #}
{% set extras = agno.agentos.get('extras', []) %}
{% if extras %}
{% set pkg = 'agno[' ~ extras | join(',') ~ ']==' ~ agno.agentos.version %}
{% else %}
{% set pkg = 'agno==' ~ agno.agentos.version %}
{% endif %}

agno-agentos-install:
  pip.installed:
    - name: {{ pkg }}
