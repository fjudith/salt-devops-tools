# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import opencost with context %}

opencost-archive:
  file.absent:
    - name: /usr/local/opencost/{{ opencost.version }}

opencost:
  file.absent:
    - name: /usr/local/bin/kubectl-cost
