# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import k9s with context %}

k9s-archive:
  file.absent:
    - name: /usr/local/k9s/{{ k9s.version }}

k9s:
  file.absent:
    - name: /usr/local/bin/k9s
