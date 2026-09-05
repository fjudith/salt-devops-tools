# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import multica with context %}

multica-archive:
  file.absent:
    - name: /usr/local/multica/{{ multica.version }}

multica:
  file.absent:
    - name: /usr/local/bin/multica

multica-service:
  service.dead:
    - name: multica
    - enable: false

multica-service-unit:
  file.absent:
    - name: /etc/systemd/system/multica.service
    - require:
      - service: multica-service
