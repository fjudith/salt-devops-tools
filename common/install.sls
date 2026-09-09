# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import common with context %}

{% set repoState = 'removed' %}
{% if common.enabled %}
  {% set repoState = 'installed' %}
{% endif %}


common-packages:
  pkg.{{ repoState }}:
    - skip_suggestions: True
    - refresh: True
    - allow_updates: True
    - pkgs:
      {%- for item in common.common %}
      - {{ item }}
      {% endfor %}

{% if common.enabled %}
cni-default-config:
  file.managed:
    - name: /etc/cni/net.d/99-default.conf
    - makedirs: True
    - contents: |
        {
          "cniVersion": "0.3.1",
          "name": "default",
          "plugins": [
            {
              "type": "bridge"
            },
            {
              "type": "portmap",
              "capabilities": {
                "portMappings": true
              }
            },
            {
              "type": "loopback"
            }
          ]
        }
{% else %}
cni-default-config:
  file.absent:
    - name: /etc/cni/net.d/99-default.conf
{% endif %}

{%- if grains['os_family']|lower in ('debian',) %}
debian-packages:
  pkg.{{ repoState }}:
    - skip_suggestions: True
    - refresh: True
    - allow_updates: True
    - pkgs:
      {%- for item in common.debian %}
      - {{ item }}
      {% endfor %}
{% endif %}

{%- if grains['os_family']|lower in ('redhat',) %}
redhat-packages:
  pkg.{{ repoState }}:
    - skip_suggestions: True
    - refresh: True
    - allow_updates: True
    - pkgs:
      {%- for item in commond.redhat %}
      - {{ item }}
      {% endfor %}
{% endif %}

{%- if common.virtio.enabled %}
{%- for mod in common.virtio.modules %}
virtio-module-{{ mod }}:
  kmod.present:
    - name: {{ mod }}
    - persist: True
{% endfor %}
{% else %}
{%- for mod in common.virtio.modules %}
virtio-module-{{ mod }}:
  kmod.absent:
    - name: {{ mod }}
    - persist: True
{% endfor %}
{% endif %}

fs.inotify.max_user_watches:
  sysctl.present:
    - value: 1048576

fs.inotify.max_user_instances:
  sysctl.present:
    - value: 512
