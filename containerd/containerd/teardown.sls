# -*- coding: utf-8 -*-
# vim: ft=jinja

{%- from tpldir ~ "/map.jinja" import containerd with context %}

containerd.io:
  pkg.absent
