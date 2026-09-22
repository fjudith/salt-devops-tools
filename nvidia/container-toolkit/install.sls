# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import container_toolkit with context %}

include:
  - .repo

nvidia-container-toolkit:
  pkg.installed:
    - pkgs:
      - nvidia-container-toolkit: {{ container_toolkit.version }}
      - nvidia-container-toolkit-base: {{ container_toolkit.version }}
    - refresh: True
    - require:
      - pkgrepo: nvidia-container-toolkit-repo
