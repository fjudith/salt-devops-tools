# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from "vllm/map.jinja" import vllm with context %}

{% set docker = vllm.docker %}

{% if not docker.model %}
vllm-docker-model-required:
  test.fail_without_changes:
    - name: "vllm.docker.model must be set to a HuggingFace model repo for docker mode"
{% else %}

vllm-docker-image:
  cmd.run:
    - name: docker pull {{ docker.image }}

vllm-docker-cache-volume:
  cmd.run:
    - name: docker volume create {{ docker.cache_volume }}
    - unless: docker volume inspect {{ docker.cache_volume }}

vllm-docker-service-file:
  file.managed:
    - name: /etc/systemd/system/{{ docker.service }}.service
    - user: root
    - group: root
    - mode: '0644'
    - contents: |
        [Unit]
        Description=vLLM (Docker)
        After=docker.service network-online.target
        Requires=docker.service
        Wants=network-online.target

        [Service]
        Type=simple
        # Remove any stale container from a previous run.
        ExecStartPre=-/usr/bin/docker rm --force {{ docker.container }}
        ExecStart=/usr/bin/docker run \
          --rm \
          --name {{ docker.container }} \
          {%- if docker.gpus is not none %}
          --runtime nvidia \
          --gpus {{ docker.gpus }} \
          {%- endif %}
          {%- if docker.resources.cpu.max is not none %}
          --cpus {{ docker.resources.cpu.max }} \
          {%- endif %}
          {%- if docker.resources.cpu.min is not none %}
          --cpu-shares {{ docker.resources.cpu.min }} \
          {%- endif %}
          {%- if docker.resources.memory.max is not none %}
          --memory {{ docker.resources.memory.max }} \
          {%- endif %}
          {%- if docker.resources.memory.min is not none %}
          --memory-reservation {{ docker.resources.memory.min }} \
          {%- endif %}
          {%- if docker.hf_token %}
          --env HUGGING_FACE_HUB_TOKEN={{ docker.hf_token }} \
          {%- endif %}
          {%- if docker.api_key %}
          --env VLLM_API_KEY={{ docker.api_key }} \
          {%- endif %}
          --publish {{ docker.host_ip }}:{{ docker.port }}:8000 \
          --volume {{ docker.cache_volume }}:/root/.cache/huggingface \
          {{ docker.image }} \
          --model {{ docker.model }} \
          {%- if docker.api_key %}
          --api-key {{ docker.api_key }} \
          {%- endif %}
          {%- for arg in docker.extra_args %}
          {{ arg }} \
          {%- endfor %}
          --host 0.0.0.0 \
          --port 8000
        ExecStop=-/usr/bin/docker stop {{ docker.container }}
        Restart=always
        RestartSec=5
        KillMode=mixed

        [Install]
        WantedBy=multi-user.target
    - require:
      - cmd: vllm-docker-image
      - cmd: vllm-docker-cache-volume

vllm-docker:
  service.running:
    - name: {{ docker.service }}
    - enable: true
    - require:
      - file: vllm-docker-service-file
    - watch:
      - file: vllm-docker-service-file
{% endif %}
