# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import pixie with context %}

pixie-binary:
  file.absent:
    - name: /usr/local/pixie/{{ pixie.version }}

pixie:
  file.absent:
    - name: /usr/local/bin/px

pixie-completion:
  file.absent:
    - name: /etc/bash_completion.d/pixie