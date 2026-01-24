# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import terragrunt with context %}

terragrunt-archive:
  archive.extracted:
    - name: /usr/local/terragrunt/{{ terragrunt.version }}
    - source: https://github.com/gruntwork-io/terragrunt/releases/download/v{{ terragrunt.version }}/terragrunt_linux_amd64.tar.gz
    - source_hash: https://github.com/gruntwork-io/terragrunt/releases/download/v{{ terragrunt.version }}/SHA256SUMS
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    # - options: '--strip-components=1'
    - unless: ls /usr/local/terragrunt/{{ terragrunt.version }}

terragrunt:
  file.symlink:
    - name: /usr/local/bin/terragrunt
    - target: /usr/local/terragrunt/{{ terragrunt.version }}/terragrunt_linux_amd64
    - mode: 0755