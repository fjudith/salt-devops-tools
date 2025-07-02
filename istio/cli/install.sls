# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import istio with context %}

istio-archive:
  archive.extracted:
    - name: /usr/local/istio/{{ istio.version }}
    - source: https://github.com/istio/istio/releases/download/{{ istio.version }}/istio-{{ istio.version }}-linux-amd64.tar.gz
    - source_hash: https://github.com/istio/istio/releases/download/{{ istio.version }}/istio-{{ istio.version }}-linux-amd64.tar.gz.sha256
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    - options: '--strip-components=1'
    - unless: ls /usr/local/istio/{{ istio.version }}

istio:
  file.symlink:
    - name: /usr/local/bin/istioctl
    - target: /usr/local/istio/{{ istio.version }}/istioctl
