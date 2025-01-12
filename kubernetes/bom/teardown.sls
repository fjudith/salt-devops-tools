# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import bom with context %}

bom-binary:
  file.absent:
    - name: /usr/local/bom/{{ bom.version }}

bom:
  file.absent:
    - name: /usr/local/bin/bom
