# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import hubble with context %}

hubble-archive:
  file.absent:
    - name: /usr/local/hubble/{{ hubble.version }}

hubble:
  file.absent:
    - name: /usr/local/bin/hubble
