# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import firecracker with context %}

firecracker-archive:
  archive.extracted:
    - name: /usr/local/firecracker/{{ firecracker.version }}
    - source: https://github.com/firecracker-microvm/firecracker/releases/download/v{{ firecracker.version }}/firecracker-v{{ firecracker.version }}-x86_64.tgz
    - source_hash: https://github.com/firecracker-microvm/firecracker/releases/download/v{{ firecracker.version }}/firecracker-v{{ firecracker.version }}-x86_64.tgz.sha256.txt
    - skip_verify: false
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    - unless: ls /usr/local/firecracker/{{ firecracker.version }}

firecracker:
  file.symlink:
    - name: /usr/local/bin/firecracker
    - target: /usr/local/firecracker/{{ firecracker.version }}/release-v{{ firecracker.version }}-x86_64/firecracker-v{{ firecracker.version }}-x86_64
