# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import vllm with context %}

{% set modes = {
  'gpu': {'package': 'vllm', 'extra_args': '--extra-index-url https://download.pytorch.org/whl/cu129'},
  'cpu': {'package': 'vllm', 'extra_args': '--extra-index-url https://download.pytorch.org/whl/cpu'},
  'tpu': {'package': 'tpu-inference', 'extra_args': ''}
} %}

{% if vllm.mode not in modes %}
vllm-invalid-mode:
  test.fail_without_changes:
    - name: "vLLM mode must be one of: gpu, cpu, tpu"
{% else %}
{% set package = modes[vllm.mode].package %}
{% if vllm.version != 'latest' and vllm.mode != 'tpu' %}
  {% set package = package ~ '==' ~ vllm.version %}
{% endif %}

vllm-package:
  pip.installed:
    - name: {{ package }}
    - upgrade: {{ vllm.version == 'latest' }}
    {%- if modes[vllm.mode].extra_args %}
    - extra_args: {{ modes[vllm.mode].extra_args }}
    {%- endif %}

{% if vllm.mode != 'tpu' %}
vllm-tpu-package:
  pip.removed:
    - name: tpu-inference
{% endif %}
{% endif %}
