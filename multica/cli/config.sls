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

{#- The daemon needs `multica login` (<home>/.multica/config.json, owned by the
    service user). The file is never managed here: it is only checked. Without
    it the service is kept stopped instead of crash-looping. #}
{% set login_cfg = multica.service.home ~ '/.multica/config.json' %}
{% if multica.service.enabled and salt['file.file_exists'](login_cfg) %}
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
{% if multica.service.enabled %}
multica-login-missing:
  test.show_notification:
    - text: "{{ login_cfg }} not found: run `multica login` as {{ multica.service.user }}, then re-apply to start the multica service."
{% endif %}
multica-service:
  service.dead:
    - name: multica
    - enable: false
{% endif %}
