# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import opa with context %}

opa-binary:
  file.managed:
    - name: /usr/local/open-policy-agent/{{ opa.version }}/opa
    - source: https://github.com/open-policy-agent/opa/releases/download/v{{ opa.version }}/opa_linux_amd64
    - source_hash: https://github.com/open-policy-agent/opa/releases/download/v{{ opa.version }}/opa_linux_amd64.sha256
    - makedirs: true
    - user: root
    - group: root
    - mode: '0755'
    - unless: ls /usr/local/open-policy-agent/{{ opa.version }}

opa:
  file.symlink:
    - name: /usr/local/bin/opa
    - target: /usr/local/open-policy-agent/{{ opa.version }}/opa
    - mode: '0755'
