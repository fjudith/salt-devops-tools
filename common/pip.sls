# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import common with context %}

{% if common.enabled %}
pip-packages:
  pip.installed:
    - pkgs:
      {%- for pkg in common.pip %}
      - {{ pkg }}
      {%- endfor %}
{% else %}
pip-packages:
  pip.removed:
    - pkgs:
      {%- for pkg in common.pip %}
      - {{ pkg }}
      {%- endfor %}
{% endif %}
