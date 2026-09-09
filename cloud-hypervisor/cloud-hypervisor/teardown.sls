# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import cloud_hypervisor with context %}

cloud-hypervisor:
  file.absent:
    - name: /usr/local/cloud-hypervisor/{{ cloud_hypervisor.version }}

cloud-hypervisor-bin:
  file.absent:
    - name: /usr/local/bin/cloud-hypervisor
