# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import codegraph with context %}

codegraph-teardown-symlink:
  file.absent:
    - name: {{ codegraph.bin_dir }}/codegraph

codegraph-teardown-install-dir:
  file.absent:
    - name: {{ codegraph.install_dir }}
