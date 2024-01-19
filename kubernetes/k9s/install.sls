# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import k9s with context %}

k9s-archive:
  archive.extracted:
    - name: /usr/local/k9s/{{ k9s.version }}
    - source: https://github.com/derailed/k9s/releases/download/v{{ k9s.version }}/k9s_Linux_amd64.tar.gz
    - source_hash: https://github.com/derailed/k9s/releases/download/v{{ k9s.version }}/checksums.sha256
    - skip_verify: false
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    - unless: ls /usr/local/k9s/{{ k9s.version }}

k9s:
  file.symlink:
    - name: /usr/local/bin/k9s
    - target: /usr/local/k9s/{{ k9s.version }}/k9s
