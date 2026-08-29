# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import glab with context %}

glab-archive:
  file.absent:
    - name: /usr/local/glab/{{ glab.version }}

glab:
  file.absent:
    - name: /usr/local/bin/glab

glab-completion:
  file.absent:
    - name: /etc/bash_completion.d/glab
