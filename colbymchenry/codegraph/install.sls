# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import codegraph with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set cg_arch = 'x64' %}
{% elif arch in ['aarch64', 'arm64'] %}
  {% set cg_arch = 'arm64' %}
{% endif %}

{#- Construct download filename and URL #}
{% set filename = 'codegraph-linux-' ~ cg_arch ~ '.tar.gz' %}
{% set download_url = codegraph.repo_url ~ '/releases/download/' ~ codegraph.version ~ '/' ~ filename %}

codegraph-dependencies:
  pkg.installed:
    - pkgs:
      - curl
      - tar

codegraph-install-dir:
  file.directory:
    - name: {{ codegraph.install_dir }}
    - user: root
    - group: root
    - mode: '0755'
    - makedirs: true

codegraph-download:
  file.managed:
    - name: /tmp/{{ filename }}
    - source: {{ download_url }}
    - skip_verify: true
    - user: root
    - group: root
    - mode: '0644'
    - unless: test -x {{ codegraph.bin_dir }}/codegraph

codegraph-archive:
  archive.extracted:
    - name: {{ codegraph.install_dir }}
    - source: /tmp/{{ filename }}
    - user: root
    - group: root
    - archive_format: tar
    - options: --strip-components=1
    - enforce_toplevel: false
    - overwrite: true
    - require:
      - file: codegraph-install-dir
      - file: codegraph-download
    - unless: test -x {{ codegraph.bin_dir }}/codegraph

codegraph-symlink:
  file.symlink:
    - name: {{ codegraph.bin_dir }}/codegraph
    - target: {{ codegraph.install_dir }}/bin/codegraph
    - force: true
    - require:
      - archive: codegraph-archive

codegraph-cleanup:
  file.absent:
    - name: /tmp/{{ filename }}
    - require:
      - archive: codegraph-archive
