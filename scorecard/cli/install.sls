# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import scorecard with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
scorecard-unsupported-architecture:
  test.fail_without_changes:
    - name: "scorecard supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

scorecard-archive:
  archive.extracted:
    - name: /usr/local/scorecard/{{ scorecard.version }}
    - source: https://github.com/ossf/scorecard/releases/download/v{{ scorecard.version }}/scorecard_{{ scorecard.version }}_linux_{{ bin_arch }}.tar.gz
    - source_hash: https://github.com/ossf/scorecard/releases/download/v{{ scorecard.version }}/scorecard_checksums.txt
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    # - options: '--strip-components=1'
    - unless: ls /usr/local/scorecard/{{ scorecard.version }}

scorecard:
  file.symlink:
    - name: /usr/local/bin/scorecard
    - target: /usr/local/scorecard/{{ scorecard.version }}/scorecard-linux-{{ bin_arch }}

scorecard-completion:
  cmd.run:
    - require:
      - file: scorecard
    - name: /usr/local/bin/scorecard completion bash | tee /etc/bash_completion.d/scorecard
{% endif %}
