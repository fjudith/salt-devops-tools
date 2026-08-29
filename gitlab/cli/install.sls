# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import glab with context %}

glab-archive:
  archive.extracted:
    - name: /usr/local/glab/{{ glab.version }}
    - source: https://gitlab.com/gitlab-org/cli/-/releases/v{{ glab.version }}/downloads/glab_{{ glab.version }}_Linux_x86_64.tar.gz
    - source_hash: https://gitlab.com/gitlab-org/cli/-/releases/v{{ glab.version }}/downloads/glab_{{ glab.version }}_Linux_x86_64.tar.gz.sha256
    - skip_verify: false
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    - unless: ls /usr/local/glab/{{ glab.version }}

glab:
  file.symlink:
    - name: /usr/local/bin/glab
    - target: /usr/local/glab/{{ glab.version }}/bin/glab

glab-completion:
  cmd.run:
    - require:
      - file: glab
    - name: /usr/local/bin/glab completion -s bash > /etc/bash_completion.d/glab
