# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import kustomize with context %}

kustomize-archive:
  file.absent:
    - name: /usr/local/kustomize/{{ kustomize.version }}

kustomize:
  file.absent:
    - name: /usr/local/bin/kustomize
