# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import multica with context %}

multica-service-unit:
  file.managed:
    - name: /etc/systemd/system/multica.service
    - source: salt://multica/cli/files/multica.service
    - user: root
    - group: root
    - mode: '0644'
    - template: jinja
    - defaults:
        user: {{ multica.service.user }}
        group: {{ multica.service.group }}
        home: {{ multica.service.home }}

{% if multica.service.enabled %}
multica-service:
  service.running:
    - name: multica
    - enable: true
    - watch:
      - file: multica-service-unit
      - file: multica
    - require:
      - file: multica-service-unit
      - file: multica
{% else %}
multica-service:
  service.dead:
    - name: multica
    - enable: false
{% endif %}