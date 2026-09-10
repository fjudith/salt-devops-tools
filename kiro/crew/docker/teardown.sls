# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from "kiro/crew/map.jinja" import kirocrew with context %}

{% set docker = kirocrew.service.docker %}

kirocrew-docker:
  service.dead:
    - name: {{ docker.service }}
    - enable: false
    - onlyif: systemctl is-enabled --quiet {{ docker.service }} || systemctl is-active --quiet {{ docker.service }}

kirocrew-docker-container-teardown:
  cmd.run:
    - name: docker rm --force {{ docker.container }}
    - onlyif: docker container inspect {{ docker.container }}
    - require:
      - service: kirocrew-docker

kirocrew-docker-service-file-teardown:
  file.absent:
    - name: /etc/systemd/system/{{ docker.service }}.service
    - require:
      - service: kirocrew-docker

kirocrew-docker-login-helper-teardown:
  file.absent:
    - name: /usr/local/bin/kirocrew-docker-login

kirocrew-docker-seccomp-teardown:
  file.absent:
    - name: {{ docker.seccomp_profile }}
    - require:
      - cmd: kirocrew-docker-container-teardown
