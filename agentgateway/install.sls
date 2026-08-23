# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import agentgateway with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% set binary = 'agentgateway-linux-' ~ bin_arch %}
{% set download_url = agentgateway.base_url ~ '/v' ~ agentgateway.version ~ '/' ~ binary %}
{% set checksum_url = download_url ~ '.sha256' %}

agentgateway-install-dir:
  file.directory:
    - name: {{ agentgateway.install_dir }}/{{ agentgateway.version }}
    - user: root
    - group: root
    - mode: '0755'
    - makedirs: true

agentgateway-download:
  file.managed:
    - name: {{ agentgateway.install_dir }}/{{ agentgateway.version }}/agentgateway
    - source: {{ download_url }}
    - source_hash: {{ checksum_url }}
    - user: root
    - group: root
    - mode: '0755'
    - require:
      - file: agentgateway-install-dir
    - unless: test -f {{ agentgateway.install_dir }}/{{ agentgateway.version }}/agentgateway

agentgateway-symlink:
  file.symlink:
    - name: {{ agentgateway.bin_dir }}/agentgateway
    - target: {{ agentgateway.install_dir }}/{{ agentgateway.version }}/agentgateway
    - force: true
    - require:
      - file: agentgateway-download
