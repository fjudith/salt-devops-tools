# -*- coding: utf-8 -*-
# vim: ft=jinja
{% from tpldir ~ "/map.jinja" import strands with context %}
{% set c = strands.cli %}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch in ('x86_64', 'amd64') %}
  {% set node_arch = 'x64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set node_arch = 'arm64' %}
{% endif %}
{% if node_arch is not defined %}
strands-cli-unsupported-architecture:
  test.fail_without_changes:
    - name: "strands cli supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}
{% set node_dir = strands.root_dir ~ '/node/' ~ c.node.version %}
{% set cli_dir = strands.root_dir ~ '/cli' %}
{% set node_url = c.node.base_url ~ '/v' ~ c.node.version %}
strands-cli-node-archive:
  archive.extracted:
    - name: {{ node_dir }}
    - source: {{ node_url }}/node-v{{ c.node.version }}-linux-{{ node_arch }}.tar.xz
    - source_hash: {{ node_url }}/SHASUMS256.txt
    - source_hash_name: node-v{{ c.node.version }}-linux-{{ node_arch }}.tar.xz
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    - options: --strip-components=1
    - unless: test -x {{ node_dir }}/bin/node

strands-cli-npm:
  cmd.run:
    - name: {{ node_dir }}/bin/npm install --no-audit --no-fund --prefix {{ cli_dir }} @strands-agents/cli@{{ c.cli.version }}
    - env:
      - PATH: {{ node_dir }}/bin:/usr/local/bin:/usr/bin:/bin
    - unless: test "$({{ node_dir }}/bin/node -p "require('{{ cli_dir }}/node_modules/@strands-agents/cli/package.json').version" 2>/dev/null)" = "{{ c.cli.version }}"
    - require:
      - archive: strands-cli-node-archive

strands-cli-wrapper:
  file.managed:
    - name: {{ c.bin_dir }}/strands
    - user: root
    - group: root
    - mode: '0755'
    - contents: |
        #!/bin/sh
        # Managed by Salt (strands.cli)
        export PATH="{{ node_dir }}/bin:$PATH"
        exec "{{ cli_dir }}/node_modules/.bin/strands" "$@"
    - require:
      - cmd: strands-cli-npm
{% endif %}
