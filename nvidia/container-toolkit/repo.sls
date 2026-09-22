# -*- coding: utf-8 -*-
# vim: ft=jinja

{%- from tpldir ~ "/map.jinja" import container_toolkit with context %}

{%- if grains['os_family']|lower in ('debian',) %}

nvidia-container-toolkit-repo:
  cmd.run:
    - name: |
        curl -fsSL {{ container_toolkit.gpg_key }} \
        | gpg --yes --dearmor -o {{ container_toolkit.keyring }}
    - creates: {{ container_toolkit.keyring }}
  pkgrepo.managed:
    - require:
      - cmd: nvidia-container-toolkit-repo
    - humanname: NVIDIA Container Toolkit Package Repository
    - name: deb [signed-by={{ container_toolkit.keyring }}] {{ container_toolkit.base_url }}/stable/deb/$(ARCH) /
    - file: /etc/apt/sources.list.d/nvidia-container-toolkit.list
    - aptkey: False
    - clean_file: True
    - refresh: True

{%- elif grains['os_family']|lower in ('redhat',) %}

nvidia-container-toolkit-repo:
  pkgrepo.managed:
    - name: nvidia-container-toolkit
    - humanname: NVIDIA Container Toolkit Package Repository
    - baseurl: {{ container_toolkit.base_url }}/stable/rpm/$basearch
    - enabled: 1
    - gpgcheck: 1
    - gpgkey: {{ container_toolkit.gpg_key }}

{%- else %}
nvidia-container-toolkit-repo: {}
{%- endif %}
