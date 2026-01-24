# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import terraform_docs with context %}

terraform_docs-archive:
  file.absent:
    - name: /usr/local/terraform-docs/{{ terraform_docs.version }}

terraform_docs:
  file.absent:
    - name: /usr/local/bin/terraform-docs

terraform_docs-completion:
  file.absent:
    - name: /etc/bash_completion.d/terraform-docs
