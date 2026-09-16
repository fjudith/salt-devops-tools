# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import argocd with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
argocd-unsupported-architecture:
  test.fail_without_changes:
    - name: "argocd supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

argocd-binary:
  file.managed:
    - name: /usr/local/argocd/{{ argocd.version }}/argocd
    - source: https://github.com/argoproj/argo-cd/releases/download/v{{ argocd.version }}/argocd-linux-{{ bin_arch }}
    - source_hash: https://github.com/argoproj/argo-cd/releases/download/v{{ argocd.version }}/argocd-linux-{{ bin_arch }}.sha256
    - makedirs: true
    - user: root
    - group: root
    - mode: 755
    - unless: ls /usr/local/argocd/{{ argocd.version }}

argocd:
  file.symlink:
    - name: /usr/local/bin/argocd
    - target: /usr/local/argocd/{{ argocd.version }}/argocd
{% endif %}
