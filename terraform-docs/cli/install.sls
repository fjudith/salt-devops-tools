# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import terraform_docs with context %}

terraform-docs-archive:
  archive.extracted:
    - name: /usr/local/terraform-docs/{{ terraform_docs.version }}
    - source: https://github.com/terraform-docs/terraform-docs/releases/download/v{{ terraform_docs.version }}/terraform-docs-v{{ terraform_docs.version }}-linux-amd64.tar.gz
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