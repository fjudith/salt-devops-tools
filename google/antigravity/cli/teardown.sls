# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import antigravity with context %}

antigravity-teardown-completion:
  file.absent:
    - name: /etc/bash_completion.d/agy

antigravity-teardown-symlink:
  file.absent:
    - name: {{ antigravity.bin_dir }}/agy

antigravity-teardown-install-dir:
  file.absent:
    - name: {{ antigravity.install_dir }}
