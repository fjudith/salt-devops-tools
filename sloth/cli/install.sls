# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import sloth with context %}

sloth-binary:
  file.managed:
    - name: /usr/local/sloth/{{ sloth.version }}/sloth
    - source: https://github.com/slok/sloth/releases/download/v{{ sloth.version }}/sloth-linux-amd64
    - source_hash: https://github.com/slok/sloth/releases/download/v{{ sloth.version }}/checksums.txt
    - makedirs: true
    - user: root
    - group: root
    - mode: '0755'
    - unless: ls /usr/local/sloth/{{ sloth.version }}

sloth:
  file.symlink:
    - name: /usr/local/bin/sloth
    - target: /usr/local/sloth/{{ sloth.version }}/sloth
    - mode: '0755'
