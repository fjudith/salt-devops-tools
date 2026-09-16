# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import eksctl with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
eksctl-unsupported-architecture:
  test.fail_without_changes:
    - name: "eksctl supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

eksctl-archive:
  archive.extracted:
    - name: /usr/local/eksctl/{{ eksctl.version }}
    - source: https://github.com/eksctl-io/eksctl/releases/download/v{{ eksctl.version }}/eksctl_Linux_{{ bin_arch }}.tar.gz
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
{% endif %}
