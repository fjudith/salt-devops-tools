# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import onnx with context %}

{% set tts = onnx.tts %}

onnx-tts-teardown-models-dir:
  file.absent:
    - name: {{ tts.models_dir }}
