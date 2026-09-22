# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from "vllm/map.jinja" import vllm with context %}

{% set kata = vllm.kata %}

{% if not kata.model %}
vllm-kata-model-required:
  test.fail_without_changes:
    - name: "vllm.kata.model must be set to a HuggingFace model repo for kata mode"
{% else %}

# Persistent HuggingFace cache bind-mounted into the guest so model downloads
# survive restarts.
vllm-kata-cache-directory:
  file.directory:
    - name: {{ kata.cache_dir }}
    - user: root
    - group: root
    - mode: '0755'
    - makedirs: true

# Dedicated CNI network (bridge + IPAM + portmap) so the API port can be
# published from the guest with a fixed container IP.
vllm-kata-network:
  cmd.run:
    - name: nerdctl --namespace {{ kata.namespace }} network create {{ kata.network }} --subnet {{ kata.subnet }}
    - unless: nerdctl --namespace {{ kata.namespace }} network inspect {{ kata.network }}
    - require:
      - sls: containerd.nerdctl

# Pre-pull the image into the containerd namespace so the service starts fast
# and fails early if the image is unavailable.
vllm-kata-image:
  cmd.run:
    - name: nerdctl --namespace {{ kata.namespace }} pull {{ kata.image }}
    - unless: nerdctl --namespace {{ kata.namespace }} image inspect {{ kata.image }}
    - require:
      - sls: kata-containers.kata-containers
      - sls: containerd.nerdctl

vllm-kata-service-file:
  file.managed:
    - name: /etc/systemd/system/{{ kata.service }}.service
    - user: root
    - group: root
    - mode: '0644'
    - contents: |
        [Unit]
        Description=vLLM (Kata Containers / Cloud Hypervisor)
        After=containerd.service network-online.target
        Requires=containerd.service
        Wants=network-online.target

        [Service]
        Type=simple
        # Remove any stale container from a previous run.
        ExecStartPre=-/usr/local/bin/nerdctl --namespace {{ kata.namespace }} rm --force {{ kata.container }}
        ExecStart=/usr/local/bin/nerdctl --namespace {{ kata.namespace }} run \
          --rm \
          --name {{ kata.container }} \
          --runtime {{ kata.runtime }} \
          {%- if kata.resources.cpu.max is not none %}
          --cpus {{ kata.resources.cpu.max }} \
          {%- endif %}
          {%- if kata.resources.cpu.min is not none %}
          --cpu-shares {{ kata.resources.cpu.min }} \
          {%- endif %}
          {%- if kata.resources.memory.max is not none %}
          --memory {{ kata.resources.memory.max }} \
          {%- endif %}
          {%- if kata.resources.memory.min is not none %}
          --memory-reservation {{ kata.resources.memory.min }} \
          {%- endif %}
          {%- if kata.hf_token %}
          --env HUGGING_FACE_HUB_TOKEN={{ kata.hf_token }} \
          {%- endif %}
          {%- if kata.api_key %}
          --env VLLM_API_KEY={{ kata.api_key }} \
          {%- endif %}
          --network {{ kata.network }} \
          --ip {{ kata.container_ip }} \
          --volume {{ kata.cache_dir }}:{{ kata.cache_mount }} \
          {{ kata.image }} \
          --model {{ kata.model }} \
          {%- if kata.api_key %}
          --api-key {{ kata.api_key }} \
          {%- endif %}
          {%- for arg in kata.extra_args %}
          {{ arg }} \
          {%- endfor %}
          --host 0.0.0.0 \
          --port 8000
        ExecStop=-/usr/local/bin/nerdctl --namespace {{ kata.namespace }} stop {{ kata.container }}
        Restart=always
        RestartSec=5
        KillMode=mixed

        [Install]
        WantedBy=multi-user.target
    - require:
      - file: vllm-kata-cache-directory
      - cmd: vllm-kata-image
      - cmd: vllm-kata-network

vllm-kata:
  service.running:
    - name: {{ kata.service }}
    - enable: true
    - require:
      - sls: kata-containers.kata-containers
      - sls: containerd.nerdctl
      - file: vllm-kata-service-file
    - watch:
      - file: vllm-kata-service-file

# --- Host-side port forwarding so WSL2 mirrors the API to Windows ---
# A systemd .socket opens a REAL listening socket on host_ip:port (which WSL2's
# localhost-forwarding detects and mirrors to Windows), and systemd-socket-
# proxyd forwards accepted connections into the Kata container at its fixed IP.
# This gives Windows access while keeping full Kata VM isolation.

vllm-kata-proxy-socket-file:
  file.managed:
    - name: /etc/systemd/system/{{ kata.proxy_service }}.socket
    - user: root
    - group: root
    - mode: '0644'
    - contents: |
        [Unit]
        Description=vLLM Kata API proxy socket

        [Socket]
        ListenStream={{ kata.host_ip }}:{{ kata.port }}

        [Install]
        WantedBy=sockets.target

vllm-kata-proxy-service-file:
  file.managed:
    - name: /etc/systemd/system/{{ kata.proxy_service }}.service
    - user: root
    - group: root
    - mode: '0644'
    - contents: |
        [Unit]
        Description=vLLM Kata API proxy
        Requires={{ kata.proxy_service }}.socket
        After={{ kata.proxy_service }}.socket {{ kata.service }}.service
        BindsTo={{ kata.service }}.service

        [Service]
        ExecStart=/lib/systemd/systemd-socket-proxyd {{ kata.container_ip }}:{{ kata.port }}
    - require:
      - file: vllm-kata-proxy-socket-file

vllm-kata-proxy-socket:
  service.running:
    - name: {{ kata.proxy_service }}.socket
    - enable: true
    - require:
      - service: vllm-kata
      - file: vllm-kata-proxy-service-file
    - watch:
      - file: vllm-kata-proxy-socket-file
      - file: vllm-kata-proxy-service-file
{% endif %}
