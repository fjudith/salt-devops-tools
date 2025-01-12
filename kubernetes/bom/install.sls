# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import bom with context %}

bom-binary:
  file.managed:
    - name: /usr/local/bom/{{ bom.version }}/bom
    - source: https://github.com/kubernetes-sigs/bom/releases/download/v{{ bom.version }}/bom-amd64-linux
    - source_hash: https://github.com/kubernetes-sigs/bom/releases/download/v{{ bom.version }}/checksums.txt
    - makedirs: true
    - user: root
    - group: root
    - mode: '0755'
    - unless: ls /usr/local/bom/{{ bom.version }}

bom:
  file.symlink:
    - name: /usr/local/bin/bom
    - target: /usr/local/bom/{{ bom.version }}/bom
    - mode: '0755'
