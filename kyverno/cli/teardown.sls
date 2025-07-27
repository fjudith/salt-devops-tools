# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import kyverno with context %}

kyverno-archive:
  file.absent:
    - name: /usr/local/kyverno/{{ kyverno.version }}

kyverno:
  file.absent:
    - name: /usr/local/bin/kyverno
