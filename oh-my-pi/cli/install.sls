# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import omp with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch in ('x86_64', 'amd64') %}
  {% set bin_arch = 'x64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{#- Detect libc: musl builds link libstdc++/libgcc dynamically #}
{% set libc = 'linux' %}
{% if salt['file.file_exists']('/etc/alpine-release') %}
  {% set libc = 'linux-musl' %}
{% endif %}

{% set binary = 'omp-' ~ libc ~ '-' ~ bin_arch %}
{% set download_url = omp.base_url ~ '/v' ~ omp.version ~ '/' ~ binary %}
{% set checksum_url = omp.base_url ~ '/v' ~ omp.version ~ '/SHA256SUMS.txt' %}

omp-install-dir:
  file.directory:
    - name: {{ omp.install_dir }}/{{ omp.version }}
    - user: root
    - group: root
    - mode: '0755'
    - makedirs: true

omp-download:
  file.managed:
    - name: {{ omp.install_dir }}/{{ omp.version }}/omp
    - source: {{ download_url }}
    - source_hash: {{ checksum_url }}
    - user: root
    - group: root
    - mode: '0755'
    - require:
      - file: omp-install-dir
    - unless: test -f {{ omp.install_dir }}/{{ omp.version }}/omp

omp-symlink:
  file.symlink:
    - name: {{ omp.bin_dir }}/omp
    - target: {{ omp.install_dir }}/{{ omp.version }}/omp
    - force: true
    - require:
      - file: omp-download

{%- if omp.completion %}
omp-completion:
  cmd.run:
    - name: {{ omp.bin_dir }}/omp completions bash | tee /etc/bash_completion.d/omp
    - creates: /etc/bash_completion.d/omp
    - require:
      - file: omp-symlink
{%- endif %}
