# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import cilium with context %}

cilium-archive:
  file.absent:
    - name: /usr/local/cilium/{{ cilium.version }}

cilium:
  file.absent:
    - name: /usr/local/bin/cilium
