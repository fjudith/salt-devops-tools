# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import sloth with context %}

sloth-binary:
  file.absent:
    - name: /usr/local/sloth/{{ sloth.version }}

sloth:
  file.absent:
    - name: /usr/local/bin/sloth
