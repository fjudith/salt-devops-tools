# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import agentgateway with context %}

agentgateway-group:
  group.present:
    - name: {{ agentgateway.group }}
    - system: true

agentgateway-user:
  user.present:
    - name: {{ agentgateway.user }}
    - gid: {{ agentgateway.group }}
    - home: /home/{{ agentgateway.user }}
    - createhome: true
    - shell: /usr/sbin/nologin
    - system: true
    - require:
      - group: agentgateway-group

agentgateway-config-dir:
  file.directory:
    - name: /home/{{ agentgateway.user }}/.config/agentgateway
    - user: {{ agentgateway.user }}
    - group: {{ agentgateway.group }}
    - mode: '0750'
    - makedirs: true
    - require:
      - user: agentgateway-user

agentgateway-config-file:
  file.managed:
    - name: /home/{{ agentgateway.user }}/.config/agentgateway/config.yaml
    - source: salt://agentgateway/files/config.yaml
    - user: {{ agentgateway.user }}
    - group: {{ agentgateway.group }}
    - mode: '0640'
    - replace: false
    - template: jinja
    - defaults:
        admin_addr: {{ agentgateway.config.admin_addr }}
        stats_addr: {{ agentgateway.config.stats_addr }}
        readiness_addr: {{ agentgateway.config.readiness_addr }}
    - require:
      - file: agentgateway-config-dir

agentgateway-service-unit:
  file.managed:
    - name: /etc/systemd/system/agentgateway.service
    - source: salt://agentgateway/files/agentgateway.service
    - user: root
    - group: root
    - mode: '0644'
    - template: jinja
    - defaults:
        user: {{ agentgateway.user }}
        group: {{ agentgateway.group }}
        bin_dir: {{ agentgateway.bin_dir }}

agentgateway-service:
  service.running:
    - name: agentgateway
    - enable: true
    - watch:
      - file: agentgateway-service-unit
      - file: agentgateway-config-file
      - file: /usr/local/bin/agentgateway
    - require:
      - file: agentgateway-service-unit
      - file: agentgateway-config-file
