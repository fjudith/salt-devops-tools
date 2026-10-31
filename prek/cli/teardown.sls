# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import prek with context %}

prek-teardown-completion:
  file.absent:
    - name: /etc/bash_completion.d/prek

prek-teardown-symlink:
  file.absent:
    - name: {{ prek.bin_dir }}/prek

prek-teardown-install-dir:
  file.absent:
    - name: {{ prek.install_dir }}
