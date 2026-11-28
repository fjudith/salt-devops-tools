# -*- coding: utf-8 -*-
# vim: ft=jinja
{% from tpldir ~ "/map.jinja" import aidlc with context %}
aidlc-teardown-symlink:
  file.absent:
    - name: {{ aidlc.bin_dir }}/aidlc
aidlc-teardown-install-dir:
  file.absent:
    - name: {{ aidlc.install_dir }}
