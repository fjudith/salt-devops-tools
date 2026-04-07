# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import firecracker with context %}

firecracker-archive:
  file.absent:
    - name: /usr/local/firecracker/{{ firecracker.version }}

firecracker:
  file.absent:
    - name: /usr/local/bin/firecracker
