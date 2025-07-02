# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import istio with context %}

istio-archive:
  file.absent:
    - name: /usr/local/istio/{{ istio.version }}

istioctl:
  file.absent:
    - name: /usr/local/bin/istioctl

