# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import gotask with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
gotask-unsupported-architecture:
  test.fail_without_changes:
    - name: "task supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

gotask-archive:
  archive.extracted:
    - name: /usr/local/gotask/{{ gotask.version }}
    - source: https://github.com/go-task/task/releases/download/v{{ gotask.version }}/task_linux_{{ bin_arch }}.tar.gz
    - source_hash: https://github.com/go-task/task/releases/download/v{{ gotask.version }}/task_checksums.txt
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    # - options: '--strip-components=1'
    - unless: ls /usr/local/gotask/{{ gotask.version }}

gotask:
  file.symlink:
    - name: /usr/local/bin/task
    - target: /usr/local/gotask/{{ gotask.version }}/task

gotask-completion:
  cmd.run:
    - require:
      - file: gotask
    - name: /usr/local/bin/task --completion bash | tee /etc/bash_completion.d/task
{% endif %}
