# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import oslo with context %}

oslo-archive:
  archive.extracted:
    - name: /usr/local/oslo/{{ oslo.version }}
    - source: https://github.com/OpenSLO/oslo/releases/download/v{{ oslo.version }}/oslo_linux_x86_64.tar.gz
    - source_hash: https://github.com/OpenSLO/oslo/releases/download/v{{ oslo.version }}/oslo_{{ oslo.version }}_checksums.txt
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    # - options: '--strip-components=1'
    - unless: ls /usr/local/oslo/{{ oslo.version }}

oslo:
  file.symlink:
    - name: /usr/local/bin/oslo
    - target: /usr/local/oslo/{{ oslo.version }}/bin/oslo

oslo-completion:
  cmd.run:
    - require:
      - file: oslo
    - name: /usr/local/bin/oslo completion bash | tee /etc/bash_completion.d/oslo