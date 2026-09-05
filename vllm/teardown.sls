# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import vllm with context %}

{% set packages = ['vllm'] %}
{% if vllm.mode == 'tpu' %}
  {% set packages = ['tpu-inference', 'vllm'] %}
{% endif %}

{% for package in packages %}
vllm-{{ package }}:
  pip.removed:
    - name: {{ package }}
{% endfor %}
