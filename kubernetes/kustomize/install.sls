# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import kustomize with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
kustomize-unsupported-architecture:
  test.fail_without_changes:
    - name: "kustomize supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

kustomize-archive:
  archive.extracted:
    - name: /usr/local/kustomize/{{ kustomize.version }}
    - source: https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv{{ kustomize.version }}/kustomize_v{{ kustomize.version }}_linux_{{ bin_arch }}.tar.gz
    - source_hash: https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv{{ kustomize.version }}/checksums.txt
    - skip_verify: false
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    - unless: ls /usr/local/kustomize/{{ kustomize.version }}

kustomize:
  file.symlink:
    - name: /usr/local/bin/kustomize
    - target: /usr/local/kustomize/{{ kustomize.version }}/kustomize
    - require:
      - archive: kustomize-archive
{% endif %}
