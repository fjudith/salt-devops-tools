# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import opa with context %}

opa-binary:
  file.absent:
    - name: /usr/local/opa/{{ opa.version }}

opa:
  file.absent:
    - name: /usr/local/bin/opa
