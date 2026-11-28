# -*- coding: utf-8 -*-
# vim: ft=jinja
{% from tpldir ~ "/map.jinja" import uv with context %}
uv-teardown-symlink:
  file.absent:
    - name: {{ uv.bin_dir }}/uv
uv-teardown-uvx-symlink:
  file.absent:
    - name: {{ uv.bin_dir }}/uvx
uv-teardown-install-dir:
  file.absent:
    - name: {{ uv.install_dir }}
