# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import conftest with context %}

{#- Detect architecture #}
{% set arch = salt['grains.get']('cpuarch') %}
{% if arch == 'x86_64' %}
  {% set bin_arch = 'amd64' %}
{% elif arch in ('aarch64', 'arm64') %}
  {% set bin_arch = 'arm64' %}
{% endif %}

{% if bin_arch is not defined %}
conftest-unsupported-architecture:
  test.fail_without_changes:
    - name: "conftest supports x86_64 and aarch64 only (detected: {{ arch }})"
{% else %}

conftest:
  {%- if conftest.enabled %}
  pkg.installed:
    - sources:
      {%- if grains['os_family']|lower in ('debian',) %}
      - conftest: https://github.com/open-policy-agent/conftest/releases/download/v{{ conftest.version }}/conftest_{{ conftest.version }}_linux_{{ bin_arch }}.deb
      {%- elif grains['os_family']|lower in ('redhat',) %}
      - conftest: https://github.com/open-policy-agent/conftest/releases/download/v{{ conftest.version }}/conftest_{{ conftest.version }}_linux_{{ bin_arch }}.rpm
      {%- endif %}
  {%- else %}
  pkg.removed:
    - name: mccli
  {%- endif %}
{% endif %}
