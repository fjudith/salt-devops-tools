# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import kata_containers with context %}

{% if grains['cpuarch'] == 'x86_64' %}
{% set arch = 'amd64' %}
{% elif grains['cpuarch'] in ('aarch64', 'arm64') %}
{% set arch = 'arm64' %}
{% else %}
kata-containers-unsupported-architecture:
  test.fail_without_changes:
    - name: "Kata Containers supports x86_64 and aarch64 only"
{% endif %}

{% if grains['cpuarch'] in ('x86_64', 'aarch64', 'arm64') %}
{% set tarball = 'kata-static-' ~ kata_containers.version ~ '-' ~ arch ~ '.tar.xz' %}

kata-containers-kvm-check:
  cmd.run:
    - name: test -e /dev/kvm
    - failhard: false

kata-containers-archive:
  archive.extracted:
    - name: /
    - source: {{ kata_containers.base_url }}/{{ kata_containers.version }}/{{ tarball }}
    - source_hash: {{ kata_containers.get('source_hash', '') }}
    {%- if not kata_containers.get('source_hash') %}
    - skip_verify: true
    {%- endif %}
    - enforce_toplevel: false
    - keep_source: true
    - unless: test -x {{ kata_containers.install_dir }}/bin/kata-runtime && {{ kata_containers.install_dir }}/bin/kata-runtime --version | grep -q "{{ kata_containers.version }}"

kata-containers-runtime-symlink:
  file.symlink:
    - name: /usr/local/bin/kata-runtime
    - target: {{ kata_containers.install_dir }}/bin/kata-runtime
    - force: true
    - require:
      - archive: kata-containers-archive

kata-containers-shim-symlink:
  file.symlink:
    - name: /usr/local/bin/containerd-shim-kata-v2
    - target: {{ kata_containers.install_dir }}/bin/containerd-shim-kata-v2
    - force: true
    - require:
      - archive: kata-containers-archive
{% endif %}
