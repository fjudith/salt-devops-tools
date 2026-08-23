# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import kirocrew with context %}

kirocrew:
  {%- if kirocrew.enabled %}
  pkg.installed:
    - sources:
      {%- if grains['os_family']|lower in ('debian',) %}
      {%- if grains['cpuarch'] == 'x86_64' %}
      - kirocrew: {{ kirocrew.base_url }}/v{{ kirocrew.version }}/KiroCrew-{{ kirocrew.version }}-amd64.deb
      {%- elif grains['cpuarch'] in ('aarch64', 'arm64') %}
      - kirocrew: {{ kirocrew.base_url }}/v{{ kirocrew.version }}/KiroCrew-{{ kirocrew.version }}-arm64.deb
      {%- endif %}
      {%- elif grains['os_family']|lower in ('redhat',) %}
      {%- if grains['cpuarch'] == 'x86_64' %}
      - kirocrew: {{ kirocrew.base_url }}/v{{ kirocrew.version }}/KiroCrew-{{ kirocrew.version }}-x86_64.rpm
      {%- elif grains['cpuarch'] in ('aarch64', 'arm64') %}
      - kirocrew: {{ kirocrew.base_url }}/v{{ kirocrew.version }}/KiroCrew-{{ kirocrew.version }}-aarch64.rpm
      {%- endif %}
      {%- endif %}
  {%- else %}
  pkg.removed:
    - name: kirocrew
  {%- endif %}
