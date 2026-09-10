# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import kirocrew with context %}

{% set service_user = kirocrew.service.user %}
{% set service_bin = kirocrew.service.bin %}

{% if service_user and service_bin %}
kirocrew-service-uninstall:
  cmd.run:
    - name: {{ service_bin }} service uninstall
    - runas: {{ service_user }}
    - onlyif: systemctl is-enabled --quiet kirocrew.service
{% endif %}
