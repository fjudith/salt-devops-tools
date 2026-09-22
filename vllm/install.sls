# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import vllm with context %}

{% set flavors = {
  'gpu': {'package': 'vllm', 'extra_args': '--extra-index-url https://download.pytorch.org/whl/cu129'},
  'cpu': {'package': 'vllm', 'extra_args': '--extra-index-url https://download.pytorch.org/whl/cpu'},
  'tpu': {'package': 'tpu-inference', 'extra_args': ''}
} %}

{% if vllm.flavor not in flavors %}
vllm-invalid-flavor:
  test.fail_without_changes:
    - name: "vLLM flavor must be one of: gpu, cpu, tpu"
{% else %}
{% set package = flavors[vllm.flavor].package %}
{% if vllm.version != 'latest' and vllm.flavor != 'tpu' %}
  {% set package = package ~ '==' ~ vllm.version %}
{% endif %}

vllm-package:
  pip.installed:
    - name: {{ package }}
    - upgrade: {{ vllm.version == 'latest' }}
    {%- if flavors[vllm.flavor].extra_args %}
    - extra_args: {{ flavors[vllm.flavor].extra_args }}
    {%- endif %}

{% if vllm.flavor != 'tpu' %}
vllm-tpu-package:
  pip.removed:
    - name: tpu-inference
{% endif %}
{% endif %}
