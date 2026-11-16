# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import mssql with context %}

{% set pkgState = 'removed' %}
{% if mssql.enabled %}
  {% set pkgState = 'installed' %}
{% endif %}

odbc-dependencies:
  pkg.installed:
    - pkgs:
      {%- if grains['os_family']|lower in ('debian',) %}
      - build-essential
      - ca-certificates
      - python3-dev
      - lsb-release
      {%- elif grains['os_family']|lower in ('redhat',) %}
      - epel-release
      - gcc-c++
      - system-lsb-core
      {%- endif %}

odbc:
  pkg.{{ pkgState }}:
    - pkgs:
      {%- if grains['os_family']|lower in ('debian',) %}
      - freetds-dev
      - unixodbc-dev
      - tdsodbc
      {%- elif grains['os_family']|lower in ('redhat',) %}
      - unixODBC-devel
      - freetds-devel
      {%- endif %}

mssql:
  {#- Debian: pass ACCEPT_EULA to the apt transaction only (no state change on every run).
      RedHat: aptpkg's `env` has no yum equivalent, so keep environ.setenv there. #}
  {%- if grains['os_family']|lower in ('redhat',) %}
  environ.setenv:
    - name: ACCEPT_EULA
    - value: Y
    - update_minion: true
  {%- endif %}
  pkg.{{ pkgState }}:
    {%- if pkgState == 'installed' and grains['os_family']|lower in ('debian',) %}
    - env:
      - ACCEPT_EULA: 'Y'
    {%- endif %}
    - require:
      - pkg: odbc
    - pkgs:
      - msodbcsql17: {{ mssql.17.version }}-1
      - mssql-tools: {{ mssql.17.version }}-1
      - msodbcsql18: {{ mssql.18.version }}-1
      - mssql-tools18: {{ mssql.18.version}}-1
