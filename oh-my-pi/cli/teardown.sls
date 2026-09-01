# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import omp with context %}

omp-teardown-completion:
  file.absent:
    - name: /etc/bash_completion.d/omp

omp-teardown-symlink:
  file.absent:
    - name: {{ omp.bin_dir }}/omp

omp-teardown-install-dir:
  file.absent:
    - name: {{ omp.install_dir }}
