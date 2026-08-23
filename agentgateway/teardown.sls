# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import agentgateway with context %}

agentgateway-teardown-service:
  service.dead:
    - name: agentgateway
    - enable: false

agentgateway-teardown-unit:
  file.absent:
    - name: /etc/systemd/system/agentgateway.service
    - require:
      - service: agentgateway-teardown-service

agentgateway-teardown-symlink:
  file.absent:
    - name: {{ agentgateway.bin_dir }}/agentgateway

agentgateway-teardown-install-dir:
  file.absent:
    - name: {{ agentgateway.install_dir }}

agentgateway-teardown-user:
  user.absent:
    - name: {{ agentgateway.user }}
    - purge: true
    - require:
      - service: agentgateway-teardown-service

agentgateway-teardown-group:
  group.absent:
    - name: {{ agentgateway.group }}
    - require:
      - user: agentgateway-teardown-user
