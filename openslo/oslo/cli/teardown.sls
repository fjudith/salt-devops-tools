# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import oslo with context %}

oslo-archive:
  file.absent:
    - name: /usr/local/oslo/{{ oslo.version }}

oslo:
  file.absent:
    - name: /usr/local/bin/oslo

oslo-completion:
  file.absent:
    - name: /etc/bash_completion.d/oslo
