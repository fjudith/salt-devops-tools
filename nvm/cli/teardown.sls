# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import nvm with context %}

nvm-teardown-install:
  file.absent:
    - name: {{ nvm.install_dir }}/{{ nvm.version }}

nvm-teardown-profile:
  file.absent:
    - name: /etc/profile.d/nvm.sh
