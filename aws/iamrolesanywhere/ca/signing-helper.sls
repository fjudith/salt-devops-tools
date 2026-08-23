# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import ira with context %}

{% set sh = ira.signing_helper %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'X86_64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'Aarch64' %}
{% endif %}

{% set helper_url = sh.base_url ~ '/' ~ sh.version ~ '/' ~  bin_arch ~ '/Linux/Amzn2023/aws_signing_helper' %}

# Install the AWS IAM Roles Anywhere credential helper
rolesanywhere-signing-helper-dir:
  file.directory:
    - name: {{ sh.install_dir }}/{{ sh.version }}
    - user: root
    - group: root
    - mode: '0755'
    - makedirs: true

rolesanywhere-signing-helper-download:
  file.managed:
    - name: {{ sh.install_dir }}/{{ sh.version }}/aws_signing_helper
    - source: {{ helper_url }}
    - skip_verify: true
    - user: root
    - group: root
    - mode: '0755'
    - require:
      - file: rolesanywhere-signing-helper-dir
    - unless: test -f {{ sh.install_dir }}/{{ sh.version }}/aws_signing_helper

rolesanywhere-signing-helper-symlink:
  file.symlink:
    - name: {{ sh.bin_dir }}/aws_signing_helper
    - target: {{ sh.install_dir }}/{{ sh.version }}/aws_signing_helper
    - force: true
    - require:
      - file: rolesanywhere-signing-helper-download
