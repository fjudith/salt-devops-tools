# -*- coding: utf-8 -*-
# vim: ft=jinja
{% from tpldir ~ "/map.jinja" import strands with context %}
{% set b = strands.box %}
strands-box-teardown-symlink:
  file.absent:
    - name: {{ b.bin_dir }}/box

strands-box-teardown-install-dir:
  file.absent:
    - name: {{ b.install_dir }}
