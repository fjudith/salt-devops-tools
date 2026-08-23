# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import kirocli with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set kiro_arch = 'x86_64' %}
{% elif arch in ['aarch64', 'arm64'] %}
  {% set kiro_arch = 'aarch64' %}
{% endif %}

{#- Determine libc variant (musl vs gnu) #}
{% set os_family = salt['grains.get']('os_family') %}
{% if os_family == 'Alpine' %}
  {% set libc = 'musl' %}
{% else %}
  {% set libc = 'gnu' %}
{% endif %}

{#- Construct download filename and URL #}
{% if libc == 'musl' %}
  {% set filename = 'kirocli-' ~ kiro_arch ~ '-linux-musl.zip' %}
{% else %}
  {% set filename = 'kirocli-' ~ kiro_arch ~ '-linux.zip' %}
{% endif %}

{% set download_url = kirocli.base_url ~ '/' ~ kirocli.channel ~ '/latest/' ~ filename %}
{% set manifest_url = kirocli.base_url ~ '/' ~ kirocli.channel ~ '/latest/manifest.json' %}

kirocli-dependencies:
  pkg.installed:
    - pkgs:
      - curl
      - unzip

kirocli-install-dir:
  file.directory:
    - name: {{ kirocli.install_dir }}
    - user: root
    - group: root
    - mode: '0755'
    - makedirs: true

kirocli-download:
  file.managed:
    - name: /tmp/{{ filename }}
    - source: {{ download_url }}
    - skip_verify: true
    - user: root
    - group: root
    - mode: '0644'
    - unless: test -x {{ kirocli.bin_dir }}/kiro-cli

kirocli-archive:
  archive.extracted:
    - name: {{ kirocli.install_dir }}
    - source: /tmp/{{ filename }}
    - user: root
    - group: root
    - archive_format: zip
    - enforce_toplevel: false
    - overwrite: true
    - require:
      - file: kirocli-install-dir
      - file: kirocli-download
    - unless: test -x {{ kirocli.bin_dir }}/kiro-cli

kirocli-install:
  cmd.run:
    - name: {{ kirocli.install_dir }}/kirocli/install.sh
    - cwd: {{ kirocli.install_dir }}
    - runas: root
    - env:
      - KIRO_CLI_SKIP_SETUP: '1'
    - require:
      - archive: kirocli-archive
    - unless: test -x {{ kirocli.bin_dir }}/kiro-cli

kirocli-symlink:
  file.symlink:
    - name: {{ kirocli.bin_dir }}/kiro-cli
    - target: {{ kirocli.install_dir }}/kirocli/kiro-cli
    - force: true
    - require:
      - cmd: kirocli-install

kirocli-chat-symlink:
  file.symlink:
    - name: {{ kirocli.bin_dir }}/kiro-cli-chat
    - target: {{ kirocli.install_dir }}/kirocli/kiro-cli-chat
    - force: true
    - require:
      - cmd: kirocli-install

kirocli-cleanup:
  file.absent:
    - name: /tmp/{{ filename }}
    - require:
      - cmd: kirocli-install
