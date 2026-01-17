# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import eksctl with context %}

eksctl-archive:
  file.absent:
    - name: /usr/local/eksctl/{{ eksctl.version }}

eksctl:
  file.absent:
    - name: /usr/local/bin/eksctl
