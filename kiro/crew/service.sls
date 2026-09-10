# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import kirocrew with context %}

{% set service_user = kirocrew.service.user %}
{% if not service_user %}
kirocrew-service-user-required:
  test.fail_without_changes:
    - name: "kirocrew.service.user must identify a non-root user"
{% elif service_user == 'root' %}
kirocrew-service-user-not-root:
  test.fail_without_changes:
    - name: "Kiro Crew must run as a non-root user"
{% else %}
kirocrew-service-install:
  cmd.run:
    - name: {{ kirocrew.service.bin }} service install
    - runas: {{ service_user }}
    - unless: systemctl is-enabled --quiet kirocrew.service
    - require:
      - pkg: kirocrew

kirocrew-service:
  service.running:
    - name: kirocrew
    - enable: true
    - require:
      - pkg: kirocrew
      - cmd: kirocrew-service-install
{% endif %}
