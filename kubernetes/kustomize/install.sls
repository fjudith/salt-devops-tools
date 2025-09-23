# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import kustomize with context %}

kustomize-archive:
  archive.extracted:
    - name: /usr/local/kustomize/{{ kustomize.version }}
    - source: https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv{{ kustomize.version }}/kustomize_v{{ kustomize.version }}_linux_amd64.tar.gz
    - source_hash: https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv{{ kustomize.version }}/checksums.txt
    - skip_verify: false
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    - unless: ls /usr/local/kustomize/{{ kustomize.version }}

kustomize:
  require:
    - archive: kustomize-archive
  file.symlink:
    - name: /usr/local/bin/kustomize
    - target: /usr/local/kustomize/{{ kustomize.version }}/kustomize
