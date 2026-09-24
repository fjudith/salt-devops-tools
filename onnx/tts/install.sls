# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import onnx with context %}

{% set tts = onnx.tts %}
{% set models_dir = tts.models_dir %}

onnx-tts-models-dir:
  file.directory:
    - name: {{ models_dir }}
    - user: {{ tts.user }}
    - group: {{ tts.group }}
    - mode: '0755'
    - makedirs: true

{% for voice_name, voice in tts.get('voices', {}).items() %}

onnx-tts-{{ voice_name }}-dir:
  file.directory:
    - name: {{ models_dir }}/{{ voice_name }}
    - user: {{ tts.user }}
    - group: {{ tts.group }}
    - mode: '0755'
    - require:
      - file: onnx-tts-models-dir

onnx-tts-{{ voice_name }}-model:
  file.managed:
    - name: {{ models_dir }}/{{ voice_name }}/{{ voice_name }}.onnx
    - source: {{ voice.model_url }}
    {%- if voice.get('model_hash') %}
    - source_hash: {{ voice.model_hash }}
    {%- else %}
    - skip_verify: true
    {%- endif %}
    - user: {{ tts.user }}
    - group: {{ tts.group }}
    - mode: '0644'
    - require:
      - file: onnx-tts-{{ voice_name }}-dir
    - unless: test -f {{ models_dir }}/{{ voice_name }}/{{ voice_name }}.onnx

onnx-tts-{{ voice_name }}-config:
  file.managed:
    - name: {{ models_dir }}/{{ voice_name }}/{{ voice_name }}.onnx.json
    - source: {{ voice.config_url }}
    {%- if voice.get('config_hash') %}
    - source_hash: {{ voice.config_hash }}
    {%- else %}
    - skip_verify: true
    {%- endif %}
    - user: {{ tts.user }}
    - group: {{ tts.group }}
    - mode: '0644'
    - require:
      - file: onnx-tts-{{ voice_name }}-dir
    - unless: test -f {{ models_dir }}/{{ voice_name }}/{{ voice_name }}.onnx.json

{% endfor %}
