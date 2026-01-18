# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import crossplane with context %}



crossplane-binary:
  file.managed:
    - name: /usr/local/crossplane/{{ crossplane.version }}/crossplane
    - source: https://releases.crossplane.io/stable/v{{ crossplane.version }}/bin/linux_{{grains["osarch"]}}/crank
    - skip_verify: true
    - makedirs: true
    - user: root
    - group: root
    - mode: '0755'
    - unless: ls /usr/local/crossplane/{{ crossplane.version }}

crossplane:
  file.symlink:
    - name: /usr/local/bin/crossplane
    - target: /usr/local/crossplane/{{ crossplane.version }}/crossplane
    - mode: '0755'

crossplane-completion:
  cmd.run:
    - require:
      - file: crossplane
    - name: /usr/local/bin/crossplane completions > /etc/bash_completion.d/crossplane