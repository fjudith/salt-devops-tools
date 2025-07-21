# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import kind with context %}

kind-binary:
  file.absent:
    - name: /usr/local/kind/{{ kind.version }}

kind:
  file.absent:
    - name: /usr/local/bin/kind
