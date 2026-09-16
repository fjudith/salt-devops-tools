# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import go with context %}

{#- Detect architecture. An explicit `architecture` in pillar/defaults wins;
    otherwise it is derived from the minion's cpuarch grain. #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}
{% set go_arch = go.architecture or bin_arch %}

{% if not go_arch %}
go-unsupported-architecture:
  test.fail_without_changes:
    - name: "go supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}
{% set url = 'https://go.dev/dl' ~ '/go' ~ go.version ~ '.' ~ go.platform ~ '-' ~ go_arch ~ '.tar.gz' %}

go:
  archive.extracted:
    - name: /usr/local/go/{{ go.version }}
    - source: {{ url }} 
    - skip_verify: true
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    - unless: /usr/local/go/{{ go.version }}
  environ.setenv:
    - name: GOPATH
    - value: /usr/local/go/{{ go.version }}/go
    - update_minion: true
  file.symlink:
    - name: /usr/local/bin/go
    - target:  /usr/local/go/{{ go.version }}/go/bin/go

gofmt:
  file.symlink:
    - name: /usr/local/bin/gofmt
    - target:  /usr/local/go/{{ go.version }}/go/bin/gofmt
{% endif %}
