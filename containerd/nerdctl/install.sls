# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import nerdctl with context %}

{% if grains['cpuarch'] == 'x86_64' %}
{% set arch = 'amd64' %}
{% elif grains['cpuarch'] in ('aarch64', 'arm64') %}
{% set arch = 'arm64' %}
{% else %}
nerdctl-unsupported-architecture:
  test.fail_without_changes:
    - name: "nerdctl supports x86_64 and aarch64 only"
{% endif %}

{% if grains['cpuarch'] in ('x86_64', 'aarch64', 'arm64') %}
{% set tarball = 'nerdctl-' ~ nerdctl.version ~ '-linux-' ~ arch ~ '.tar.gz' %}

nerdctl-archive:
  archive.extracted:
    - name: /usr/local/nerdctl/{{ nerdctl.version }}
    - source: {{ nerdctl.base_url }}/v{{ nerdctl.version }}/{{ tarball }}
    - source_hash: {{ nerdctl.base_url }}/v{{ nerdctl.version }}/SHA256SUMS
    - skip_verify: false
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    - keep_source: true
    - unless: test -x {{ nerdctl.install_dir }}/nerdctl && {{ nerdctl.install_dir }}/nerdctl --version | grep -q "{{ nerdctl.version }}"

nerdctl-bin:
  file.symlink:
    - name: {{ nerdctl.install_dir }}/nerdctl
    - target: /usr/local/nerdctl/{{ nerdctl.version }}/nerdctl
    - force: true
    - require:
      - archive: nerdctl-archive

nerdctl-completion:
  cmd.run:
    - name: {{ nerdctl.install_dir }}/nerdctl completion bash | tee /etc/bash_completion.d/nerdctl
    - require:
      - file: nerdctl-bin
{% endif %}
