# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import cilium with context %}

cilium-archive:
  archive.extracted:
    - name: /usr/local/cilium/{{ cilium.version }}
    - source: https://github.com/cilium/cilium-cli/releases/download/v{{ cilium.version }}/cilium-linux-amd64.tar.gz
    - source_hash: https://github.com/cilium/cilium-cli/releases/download/v{{ cilium.version }}/cilium-linux-amd64.tar.gz.sha256sum
    - skip_verify: false
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    - unless: ls /usr/local/cilium/{{ cilium.version }}

cilium:
  file.symlink:
    - name: /usr/local/bin/cilium
    - target: /usr/local/cilium/{{ cilium.version }}/cilium

cilium-completion:
  cmd.run:
    - require:
      - file: cilium
    - name: /usr/local/bin/cilium completion bash | tee /etc/bash_completion.d/cilium
