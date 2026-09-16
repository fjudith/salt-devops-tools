# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import multica with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
multica-unsupported-architecture:
  test.fail_without_changes:
    - name: "multica supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

multica-archive:
  archive.extracted:
    - name: /usr/local/multica/{{ multica.version }}
    - source: https://github.com/multica-ai/multica/releases/download/v{{ multica.version }}/multica-cli-{{ multica.version }}-linux-{{ bin_arch }}.tar.gz
    - source_hash: https://github.com/multica-ai/multica/releases/download/v{{ multica.version }}/checksums.txt
    - skip_verify: false
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    # - options: '--strip-components=1'
    - unless: ls /usr/local/multica/{{ multica.version }}

multica:
  file.symlink:
    - name: /usr/local/bin/multica
    - target: /usr/local/multica/{{ multica.version }}/multica

multica-completion:
  cmd.run:
    - require:
      - file: multica
    - name: /usr/local/bin/multica completion bash > /etc/bash_completion.d/multica
{% endif %}
