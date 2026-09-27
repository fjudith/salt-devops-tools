# -*- coding: utf-8 -*-
# vim: ft=jinja
#
# Local Piper TTS for the docker service mode.
#
# The piper CLI and piper.download_voices live inside the KiroCrew image, and
# the model must end up in the home volume the container uses. A one-shot
# container downloads the voice into the named home volume, and the
# voice_reply section of KiroCrew's config.json (on that same volume) is
# pointed at it.

{% from "kiro/crew/map.jinja" import kirocrew with context %}

{% set docker = kirocrew.service.docker %}
{% set voice = kirocrew.service.voice %}

{#- The docker home is a named volume mounted at /home/kirocrew. #}
{% set home_mount = '/home/kirocrew' %}
{% set guest_voice_dir = home_mount ~ '/' ~ voice.model_dir %}
{% set model_onnx = guest_voice_dir ~ '/' ~ voice.voice ~ '.onnx' %}
{% set model_config = model_onnx ~ '.json' %}
{#- Resolve the volume's host mountpoint once, at render time, so file.serialize
    gets a real path (it cannot evaluate a shell substitution in `name`). Empty
    until the volume exists; the states below guard on the file existing. #}
{% set vol_mp = salt['cmd.run']("docker volume inspect --format '{{.Mountpoint}}' " ~ docker.volume ~ " 2>/dev/null", ignore_retcode=True) %}

# Download the Piper voice (.onnx + .onnx.json) into the home volume using the
# image's bundled piper.download_voices. Idempotent via the config.json check
# below; the download itself skips existing files.
kirocrew-docker-voice-download:
  cmd.run:
    - name: >-
        docker run --rm
        {%- if docker.userns_host %}
        --userns=host
        {%- endif %}
        --volume {{ docker.volume }}:{{ home_mount }}
        --entrypoint sh
        {{ docker.image }}
        -c 'mkdir -p {{ guest_voice_dir }} && cd {{ guest_voice_dir }} && python3 -m piper.download_voices {{ voice.voice }}'
    {%- if vol_mp %}
    - unless: test -f "{{ vol_mp }}/{{ voice.model_dir }}/{{ voice.voice }}.onnx"
    {%- endif %}
    - require:
      - cmd: kirocrew-docker-image
      - cmd: kirocrew-docker-volume

{% if vol_mp %}
# Point KiroCrew's voice_reply config at the downloaded model. JSON merge so
# the rest of config.json is preserved. Only applied once the config exists.
kirocrew-docker-voice-config:
  file.serialize:
    - name: {{ vol_mp }}/config.json
    - serializer: json
    - merge_if_exists: true
    - mode: '0600'
    - dataset:
        voice_reply:
          provider: {{ voice.provider }}
          piper_binary: piper
          piper_model: {{ model_onnx }}
          piper_model_config: {{ model_config }}
    - onlyif: test -f {{ vol_mp }}/config.json
    - require:
      - cmd: kirocrew-docker-voice-download
{% endif %}
