# -*- coding: utf-8 -*-
# vim: ft=jinja
{% from tpldir ~ "/map.jinja" import bun with context %}
bun-teardown-symlink:
  file.absent:
    - name: {{ bun.bin_dir }}/bun
bun-teardown-bunx-symlink:
  file.absent:
    - name: {{ bun.bin_dir }}/bunx
bun-teardown-install-dir:
  file.absent:
    - name: {{ bun.install_dir }}
