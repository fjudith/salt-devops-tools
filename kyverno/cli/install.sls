# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import kyverno with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'x86_64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
kyverno-unsupported-architecture:
  test.fail_without_changes:
    - name: "kyverno supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

kyverno-archive:
  archive.extracted:
    - name: /usr/local/kyverno/{{ kyverno.version }}
    - source: https://github.com/kyverno/kyverno/releases/download/v{{ kyverno.version }}/kyverno-cli_v{{ kyverno.version }}_linux_{{ bin_arch }}.tar.gz
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
{% endif %}
