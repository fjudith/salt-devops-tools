# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import conftest with context %}

conftest:
  {%- if conftest.enabled %}
  pkg.installed:
    - sources:
      {%- if grains['os_family']|lower in ('debian',) %}
      - conftest: https://github.com/open-policy-agent/conftest/releases/download/v{{ conftest.version }}/conftest_{{ conftest.version }}_linux_amd64.deb
      {%- elif grains['os_family']|lower in ('redhat',) %}
      - conftest: https://github.com/open-policy-agent/conftest/releases/download/v{{ conftest.version }}/conftest_{{ conftest.version }}_linux_amd64.rpm
      {%- endif %}
  {%- else %}
  pkg.removed:
    - name: mccli
  {%- endif %}