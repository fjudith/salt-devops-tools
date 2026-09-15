# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import nerdctl with context %}

nerdctl-bin:
  file.absent:
    - name: {{ nerdctl.install_dir }}/nerdctl

nerdctl-completion:
  file.absent:
    - name: /etc/bash_completion.d/nerdctl

nerdctl-install:
  file.absent:
    - name: /usr/local/nerdctl
