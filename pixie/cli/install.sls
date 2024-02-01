# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import pixie with context %}

pixie-binary:
  file.managed:
    - name: /usr/local/pixie/{{ pixie.version }}/px
    - source: https://github.com/pixie-io/pixie/releases/download/release%2Fcli%2Fv{{ pixie.version }}/cli_linux_amd64
    - source_hash: https://github.com/pixie-io/pixie/releases/download/release%2Fcli%2Fv{{ pixie.version }}/cli_linux_amd64.sha256
    - makedirs: true
    - user: root
    - group: root
    - mode: 755
    - unless: ls /usr/local/pixie/{{ pixie.version }}

pixie:
  file.symlink:
    - name: /usr/local/bin/px
    - target: /usr/local/pixie/{{ pixie.version }}/px
    - mode: 755

pixie-completion:
  cmd.run:
    - require:
      - file: pixie-binary
    - name: /usr/local/bin/px completion bash | tee /etc/bash_completion.d/pixie