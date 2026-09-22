# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import agno with context %}

agno-agentos-remove:
  pip.removed:
    - name: agno
