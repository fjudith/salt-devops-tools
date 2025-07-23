# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import hubble with context %}

hubble-archive:
  archive.extracted:
    - name: /usr/local/hubble/{{ hubble.version }}
    - source: https://github.com/cilium/hubble/releases/download/v{{ hubble.version }}/hubble-linux-amd64.tar.gz
    - source_hash: https://github.com/cilium/hubble/releases/download/v{{ hubble.version }}/hubble-linux-amd64.tar.gz.sha256sum
    - skip_verify: false
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    - unless: ls /usr/local/hubble/{{ hubble.version }}

hubble:
  file.symlink:
    - name: /usr/local/bin/hubble
    - target: /usr/local/hubble/{{ hubble.version }}/hubble
