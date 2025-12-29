# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import opentofu with context %}

{% set repoState = 'absent' %}
{% if opentofu.enabled %}
  {% set repoState = 'managed' %}
{% endif %}

{%- if grains['os_family']|lower in ('debian',) %}
{% set url = 'https://packages.opentofu.org/opentofu/tofu/any/' %}

opentofu-repo:
  cmd.run:
    - name: |
        curl -fsSL https://get.opentofu.org/opentofu.gpg \
        | sudo tee /etc/apt/keyrings/opentofu.gpg \
        > /dev/null \
        && curl -fsSL https://packages.opentofu.org/opentofu/tofu/gpgkey \
        | sudo gpg --yes --no-tty --batch --dearmor -o /etc/apt/keyrings/opentofu-repo.gpg \
        > /dev/null
  pkgrepo.{{ repoState }}:
    - require:
      - cmd: opentofu-repo
    - humanname: {{ grains["os"] }} {{ grains["oscodename"] | capitalize }} OpenTofu Package Repository
    - name: |
        deb [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] {{ url }} any main
        deb-src [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] {{ url }} any main
    - file: /etc/apt/sources.list.d/opentofu.list
    - aptkey: False
    - clean_file: True
    {%- if grains['saltversioninfo'] >= [2018, 3, 0] %}
    - refresh: True
        {%- else %}
    - refresh_db: True
        {%- endif %}

{%- elif grains['os_family']|lower in ('redhat',) %}
{% set url = 'https://packages.opentofu.org/opentofu/tofu/rpm_any/rpm_any/$basearch' %}

opentofu-repo:
  pkgrepo.{{ repoState }}:
    - name: opentofy
    - humanname: {{ grains["os"] }} {{ grains["oscodename"] | capitalize }} OpenTofu Package Repository
    - base_url: {{ url }}
    - enabled: 1
    - gpgcheck: 1
    - gpgkey: |
        https://get.opentofu.org/opentofu.gpg
        https://packages.opentofu.org/opentofu/tofu/gpgkey
    - file: opentofu.repo
    {%- if grains['saltversioninfo'] >= [2018, 3, 0] %}
    - refresh: True
        {%- else %}
    - refresh_db: True
        {%- endif %}

{% endif %}