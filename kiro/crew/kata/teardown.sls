# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from "kiro/crew/map.jinja" import kirocrew with context %}

{% set kata = kirocrew.service.kata %}

kirocrew-kata:
  service.dead:
    - name: {{ kata.service }}
    - enable: false
    - onlyif: systemctl is-enabled --quiet {{ kata.service }} || systemctl is-active --quiet {{ kata.service }}

kirocrew-kata-container-teardown:
  cmd.run:
    - name: >-
        ctr --namespace {{ kata.namespace }} task kill --signal SIGKILL {{ kata.container }} 2>/dev/null;
        ctr --namespace {{ kata.namespace }} container rm {{ kata.container }}
    - onlyif: ctr --namespace {{ kata.namespace }} container ls -q | grep -qx {{ kata.container }}
    - require:
      - service: kirocrew-kata

kirocrew-kata-service-file-teardown:
  file.absent:
    - name: /etc/systemd/system/{{ kata.service }}.service
    - require:
      - service: kirocrew-kata

kirocrew-kata-login-helper-teardown:
  file.absent:
    - name: /usr/local/bin/kirocrew-kata-login
