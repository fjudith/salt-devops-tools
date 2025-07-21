# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import kind with context %}

kind-binary:
  file.managed:
    - name: /usr/local/kind/{{ kind.version }}/kind
    - source: https://github.com/kubernetes-sigs/kind/releases/download/v{{ kind.version }}/kind-linux-amd64
    - source_hash: https://github.com/kubernetes-sigs/kind/releases/download/v{{ kind.version}}/kind-linux-amd64.sha256sum
    - makedirs: true
    - user: root
    - group: root
    - mode: '0755'
    - unless: ls /usr/local/kind/{{ kind.version }}

kind:
  file.symlink:
    - name: /usr/local/bin/kind
    - target: /usr/local/kind/{{ kind.version }}/kind
    - mode: '0755'
