# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import istio with context %}

istio-archive:
  archive.extracted:
    - name: /usr/local/istio/{{ istio.version }}
    - source: https://github.com/istio/istio/releases/download/{{ istio.version }}/istioctl-{{ istio.version }}-linux-amd64.tar.gz
    - source_hash: https://github.com/istio/istio/releases/download/{{ istio.version }}/istioctl-{{ istio.version }}-linux-amd64.tar.gz.sha256
    - skip_verify: false
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    - unless: ls /usr/local/istio/{{ istio.version }}

istioctl:
  file.symlink:
    - name: /usr/local/bin/istioctl
    - target: /usr/local/istio/{{ istio.version }}/istioctl