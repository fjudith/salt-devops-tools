# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import onnx with context %}

include:
  {%- if onnx.tts.enabled %}
  - .install
  {%- elif not onnx.tts.enabled %}
  - .teardown
  {% endif %}
