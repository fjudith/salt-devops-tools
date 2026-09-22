# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import vllm with context %}

include:
  {%- if vllm.enabled and vllm.service.enabled and vllm.service.mode == 'native' %}
  - .install
  - .docker.teardown
  - .kata.teardown
  {%- elif vllm.enabled and vllm.service.enabled and vllm.service.mode == 'docker' %}
  - docker
  {%- if vllm.docker.gpus is not none %}
  - nvidia.container-toolkit
  {%- endif %}
  - .docker.service
  - .teardown
  - .kata.teardown
  {%- elif vllm.enabled and vllm.service.enabled and vllm.service.mode == 'kata' %}
  - kata-containers.kata-containers
  - containerd.nerdctl
  - .kata.service
  - .teardown
  - .docker.teardown
  {%- elif vllm.enabled %}
  {#- enabled but service disabled -> historical behaviour: pip install only #}
  - .install
  - .docker.teardown
  - .kata.teardown
  {%- else %}
  - .teardown
  - .docker.teardown
  - .kata.teardown
  {% endif %}
