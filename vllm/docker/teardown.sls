# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from "vllm/map.jinja" import vllm with context %}

{% set docker = vllm.docker %}

vllm-docker:
  service.dead:
    - name: {{ docker.service }}
    - enable: false
    - onlyif: systemctl is-enabled --quiet {{ docker.service }} || systemctl is-active --quiet {{ docker.service }}

vllm-docker-container-teardown:
  cmd.run:
    - name: docker rm --force {{ docker.container }}
    - onlyif: docker container inspect {{ docker.container }}
    - require:
      - service: vllm-docker

vllm-docker-service-file-teardown:
  file.absent:
    - name: /etc/systemd/system/{{ docker.service }}.service
    - require:
      - service: vllm-docker
