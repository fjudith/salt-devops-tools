# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from "vllm/map.jinja" import vllm with context %}

{% set kata = vllm.kata %}

vllm-kata-proxy-socket-dead:
  service.dead:
    - name: {{ kata.proxy_service }}.socket
    - enable: false
    - onlyif: systemctl is-enabled --quiet {{ kata.proxy_service }}.socket || systemctl is-active --quiet {{ kata.proxy_service }}.socket

vllm-kata-proxy-files-teardown:
  file.absent:
    - names:
      - /etc/systemd/system/{{ kata.proxy_service }}.socket
      - /etc/systemd/system/{{ kata.proxy_service }}.service
    - require:
      - service: vllm-kata-proxy-socket-dead

vllm-kata:
  service.dead:
    - name: {{ kata.service }}
    - enable: false
    - onlyif: systemctl is-enabled --quiet {{ kata.service }} || systemctl is-active --quiet {{ kata.service }}

vllm-kata-container-teardown:
  cmd.run:
    - name: >-
        ctr --namespace {{ kata.namespace }} task kill --signal SIGKILL {{ kata.container }} 2>/dev/null;
        ctr --namespace {{ kata.namespace }} container rm {{ kata.container }}
    - onlyif: ctr --namespace {{ kata.namespace }} container ls -q | grep -qx {{ kata.container }}
    - require:
      - service: vllm-kata

vllm-kata-service-file-teardown:
  file.absent:
    - name: /etc/systemd/system/{{ kata.service }}.service
    - require:
      - service: vllm-kata
