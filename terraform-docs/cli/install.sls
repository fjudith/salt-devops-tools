# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import terraform_docs with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
terraform-docs-unsupported-architecture:
  test.fail_without_changes:
    - name: "terraform-docs supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

terraform-docs-archive:
  archive.extracted:
    - name: /usr/local/terraform-docs/{{ terraform_docs.version }}
    - source: https://github.com/terraform-docs/terraform-docs/releases/download/v{{ terraform_docs.version }}/terraform-docs-v{{ terraform_docs.version }}-linux-{{ bin_arch }}.tar.gz
    - source_hash: https://github.com/terraform-docs/terraform-docs/releases/download/v{{ terraform_docs.version }}/terraform-docs-v{{ terraform_docs.version }}.sha256sum
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    # - options: '--strip-components=1'
    - unless: ls /usr/local/terraform_docs/{{ terraform_docs.version }}

terraform-docs:
  file.symlink:
    - name: /usr/local/bin/terraform-docs
    - target: /usr/local/terraform-docs/{{ terraform_docs.version }}/terraform-docs

terraform-docs-completion:
  cmd.run:
    - require:
      - file: terraform-docs
    - name: /usr/local/bin/terraform-docs completion bash | tee /etc/bash_completion.d/terraform-docs
{% endif %}
