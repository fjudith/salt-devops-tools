# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import opencost with context %}

opencost-archive:
  archive.extracted:
    - name: /usr/local/opencost/{{ opencost.version }}
    - source: https://github.com/kubecost/kubectl-cost/releases/download/v{{ opencost.version }}/kubectl-cost-linux-amd64.tar.gz
    - skip_verify: true
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    # - options: '--strip-components=1'
    - unless: ls /usr/local/opencost/{{ opencost.version }}

opencost:
  file.symlink:
    - name: /usr/local/bin/kubectl-cost
    - target: /usr/local/opencost/{{ opencost.version }}/kubectl-cost
