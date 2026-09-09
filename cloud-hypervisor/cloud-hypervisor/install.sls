# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import cloud_hypervisor with context %}

{% if grains['cpuarch'] == 'x86_64' %}
{% set binary = 'cloud-hypervisor-static' %}
{% set digest = 'sha256=448af3d4e59b22c2987f7df94c213ad40fb53a10d437e42b5ee6c4fce7c29ecc' %}
{% elif grains['cpuarch'] in ('aarch64', 'arm64') %}
{% set binary = 'cloud-hypervisor-static-aarch64' %}
{% set digest = 'sha256=f192b510eea1c710cbc439d716bb0573c223fc463dbe3e6523788a2b7ef62850' %}
{% else %}
cloud-hypervisor-unsupported-architecture:
  test.fail_without_changes:
    - name: "Cloud Hypervisor supports x86_64 and aarch64 only"
{% endif %}

{% if grains['cpuarch'] in ('x86_64', 'aarch64', 'arm64') %}
virtiofsd:
  pkg.installed

cloud-hypervisor:
  file.managed:
    - name: /usr/local/cloud-hypervisor/{{ cloud_hypervisor.version }}/{{ binary }}
    - source: {{ cloud_hypervisor.base_url }}/v{{ cloud_hypervisor.version }}/{{ binary }}
    - source_hash: {{ digest }}
    - skip_verify: false
    - user: root
    - group: root
    - mode: '0755'
    - makedirs: true

cloud-hypervisor-bin:
  file.symlink:
    - name: /usr/local/bin/cloud-hypervisor
    - target: /usr/local/cloud-hypervisor/{{ cloud_hypervisor.version }}/{{ binary }}
    - force: true
    - require:
      - file: cloud-hypervisor
{% endif %}
