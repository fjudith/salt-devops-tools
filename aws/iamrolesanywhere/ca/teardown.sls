# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import ira with context %}

rolesanywhere-ca-teardown:
  file.absent:
    - name: {{ ira.ca_dir }}

rolesanywhere-signing-helper-teardown:
  file.absent:
    - name: {{ ira.signing_helper.install_dir }}/{{ ira.signing_helper.version }}

rolesanywhere-signing-helper-symlink-teardown:
  file.absent:
    - name: {{ ira.signing_helper.bin_dir }}/aws_signing_helper
