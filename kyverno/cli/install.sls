# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import kyverno with context %}

kyverno-archive:
  archive.extracted:
    - name: /usr/local/kyverno/{{ kyverno.version }}
    - source: https://github.com/kyverno/kyverno/releases/download/v{{ kyverno.version }}/kyverno-cli_v{{ kyverno.version }}_linux_x86_64.tar.gz
    - source_hash: https://github.com/kyverno/kyverno/releases/download/v{{ kyverno.version }}/checksums.txt
    - skip_verify: false
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    - unless: ls /usr/local/kyverno/{{ kyverno.version }}

kyverno:
  file.symlink:
    - name: /usr/local/bin/kyverno
    - target: /usr/local/kyverno/{{ kyverno.version }}/kyverno

kyverno-completion:
  cmd.run:
    - require:
      - file: kyverno
    - name: /usr/local/bin/kyverno completion bash > /etc/bash_completion.d/kyverno
