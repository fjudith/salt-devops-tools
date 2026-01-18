# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import crossplane with context %}

crossplane-binary:
  file.absent:
    - name: /usr/local/crossplane/{{ crossplane.version }}

crossplane:
  file.absent:
    - name: /usr/local/bin/crossplane
