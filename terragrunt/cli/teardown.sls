# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import terragrunt with context %}

terragrunt-archive:
  file.absent:
    - name: /usr/local/terragrunt/{{ terragrunt.version }}

terragrunt:
  file.absent:
    - name: /usr/local/bin/terragrunt

terragrunt-completion:
  file.absent:
    - name: /etc/bash_completion.d/terragrunt
