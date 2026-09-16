# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import glab with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
glab-unsupported-architecture:
  test.fail_without_changes:
    - name: "glab supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

glab-archive:
  archive.extracted:
    - name: /usr/local/glab/{{ glab.version }}
    - source: https://gitlab.com/gitlab-org/cli/-/releases/v{{ glab.version }}/downloads/glab_{{ glab.version }}_linux_{{ bin_arch }}.tar.gz
    - source_hash: https://gitlab.com/gitlab-org/cli/-/releases/v{{ glab.version }}/downloads/checksums.txt
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
{% endif %}
