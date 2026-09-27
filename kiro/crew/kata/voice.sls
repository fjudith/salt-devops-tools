# -*- coding: utf-8 -*-
# vim: ft=jinja
#
# Local Piper TTS for the kata service mode.
#
# The piper CLI and the piper.download_voices module live inside the KiroCrew
# image, and the model must end up in the home the container actually uses. So
# a one-shot container (plain nerdctl run, default runtime -- no Kata VM needed
# just to fetch a file) downloads the voice into the persistent home_dir, and
# the voice_reply section of KiroCrew's config.json is pointed at it.

{% from "kiro/crew/map.jinja" import kirocrew with context %}

{% set kata = kirocrew.service.kata %}
{% set voice = kirocrew.service.voice %}

{#- Where the config + voices live on the host and inside the container. #}
{% set host_voice_dir = kata.home_dir ~ '/' ~ voice.model_dir %}
{% set guest_voice_dir = kata.home_mount ~ '/' ~ voice.model_dir %}
{% set host_config = kata.home_dir ~ '/.kiro/crew/config.json' %}
{% set model_onnx = guest_voice_dir ~ '/' ~ voice.voice ~ '.onnx' %}
{% set model_config = model_onnx ~ '.json' %}

kirocrew-kata-voice-dir:
  file.directory:
    - name: {{ host_voice_dir }}
    - user: {{ kata.home_uid }}
    - group: {{ kata.home_gid }}
    - mode: '0755'
    - makedirs: true
    - require:
      - file: kirocrew-kata-home-directory

# Download the Piper voice (.onnx + .onnx.json) into the persistent home using
# the image's bundled piper.download_voices. Idempotent: skipped once the model
# file exists on the host.
kirocrew-kata-voice-download:
  cmd.run:
    - name: >-
        nerdctl --namespace {{ kata.namespace }} run --rm
        --volume {{ kata.home_dir }}:{{ kata.home_mount }}
        --workdir {{ guest_voice_dir }}
        --entrypoint python3
        {{ kata.image }}
        -m piper.download_voices {{ voice.voice }}
    - unless: test -f {{ host_voice_dir }}/{{ voice.voice }}.onnx
    - require:
      - file: kirocrew-kata-voice-dir
      - cmd: kirocrew-kata-image

# Point KiroCrew's voice_reply config at the downloaded model. Managed as a
# JSON merge so the rest of config.json (written by the running gateway) is
# preserved. Only applied once the config file exists (after first boot).
kirocrew-kata-voice-config:
  file.serialize:
    - name: {{ host_config }}
    - serializer: json
    - merge_if_exists: true
    - user: {{ kata.home_uid }}
    - group: {{ kata.home_gid }}
    - mode: '0600'
    - dataset:
        voice_reply:
          provider: {{ voice.provider }}
          piper_binary: piper
          piper_model: {{ model_onnx }}
          piper_model_config: {{ model_config }}
    - onlyif: test -f {{ host_config }}
    - require:
      - cmd: kirocrew-kata-voice-download
