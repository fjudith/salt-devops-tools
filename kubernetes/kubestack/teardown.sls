# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import kubestack with context %}

kubestack-archive:
  file.absent:
    - name: /usr/local/kubestack/{{ kubestack.version }}

kubestack:
  file.absent:
    - name: /usr/local/bin/kbst
