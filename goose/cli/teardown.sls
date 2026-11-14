# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import goose with context %}

goose-teardown-symlink:
  file.absent:
    - name: {{ goose.bin_dir }}/goose

goose-teardown-install-dir:
  file.absent:
    - name: {{ goose.install_dir }}
