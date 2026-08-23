# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import kirocli with context %}

kirocli-teardown-kiro-cli:
  file.absent:
    - name: {{ kirocli.bin_dir }}/kiro-cli

kirocli-teardown-kiro-cli-chat:
  file.absent:
    - name: {{ kirocli.bin_dir }}/kiro-cli-chat

kirocli-teardown-install-dir:
  file.absent:
    - name: {{ kirocli.install_dir }}
