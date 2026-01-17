# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import eksctl with context %}

eksctl-archive:
  archive.extracted:
    - name: /usr/local/eksctl/{{ eksctl.version }}
    - source: https://github.com/eksctl-io/eksctl/releases/download/v{{ eksctl.version }}/eksctl_Linux_amd64.tar.gz
    - source_hash: https://github.com/eksctl-io/eksctl/releases/download/v{{ eksctl.version }}/eksctl_checksums.txt
    - skip_verify: false
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    - unless: ls /usr/local/eksctl/{{ eksctl.version }}

eksctl:
  file.symlink:
    - name: /usr/local/bin/eksctl
    - target: /usr/local/eksctl/{{ eksctl.version }}/eksctl

eksctl-completion:
  cmd.run:
    - require:
      - file: eksctl
    - name: /usr/local/bin/eksctl completion bash > /etc/bash_completion.d/eksctl
