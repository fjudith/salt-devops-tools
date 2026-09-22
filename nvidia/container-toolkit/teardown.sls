# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import container_toolkit with context %}

nvidia-container-toolkit-teardown:
  pkg.removed:
    - pkgs:
      - nvidia-container-toolkit
      - nvidia-container-toolkit-base

{%- if grains['os_family']|lower in ('debian',) %}
nvidia-container-toolkit-repo-teardown:
  pkgrepo.absent:
    - name: deb [signed-by={{ container_toolkit.keyring }}] {{ container_toolkit.base_url }}/stable/deb/$(ARCH) /

nvidia-container-toolkit-keyring-teardown:
  file.absent:
    - name: {{ container_toolkit.keyring }}
{%- endif %}
