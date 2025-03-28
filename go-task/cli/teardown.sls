# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import gotask with context %}

gotask-archive:
  file.absent:
    - name: /usr/local/gotask/{{ gotask.version }}

gotask:
  file.absent:
    - name: /usr/local/bin/task

gotask-completion:
  file.absent:
    - name: /etc/bash_completion.d/task
