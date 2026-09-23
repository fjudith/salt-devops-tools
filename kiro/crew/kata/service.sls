# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from "kiro/crew/map.jinja" import kirocrew with context %}

{% set kata = kirocrew.service.kata %}

{% for mount in kata.mounts %}
{% if not mount.get('read_only', false) %}
# Read-write bind-mount source, created on the host and shared into the guest
# over virtio-fs. Read-only sources (e.g. ~/.aws) are left as-is.
kirocrew-kata-mount-{{ loop.index0 }}:
  file.directory:
    - name: {{ mount.source }}
    - user: root
    - group: root
    - mode: '0755'
{% endif %}
{% endfor %}

# Persistent home for the container's kirocrew user (uid/gid {{ kata.home_uid }}).
# Holds KiroCrew state and kiro-cli login credentials so they survive restarts.
kirocrew-kata-home-directory:
  file.directory:
    - name: {{ kata.home_dir }}
    - user: {{ kata.home_uid }}
    - group: {{ kata.home_gid }}
    - mode: '0700'
    - makedirs: true

# One-time interactive login helper. kiro-cli login is an interactive OAuth
# flow, so it cannot run inside a state apply; this drops a helper on PATH that
# runs the login against the persistent home. Run `sudo kirocrew-kata-login`.
kirocrew-kata-login-helper:
  file.managed:
    - name: /usr/local/bin/kirocrew-kata-login
    - source: salt://kiro/crew/kata/files/kirocrew-kata-login
    - template: jinja
    - user: root
    - group: root
    - mode: '0755'
    - context:
        image: {{ kata.image }}
        home_dir: {{ kata.home_dir }}
        home_mount: {{ kata.home_mount }}
        service: {{ kata.service }}
        container: {{ kata.container }}

# Helper that prints a dashboard access URL + token from the running container.
# Run `sudo kirocrew-kata-token [TTL]`.
kirocrew-kata-token-helper:
  file.managed:
    - name: /usr/local/bin/kirocrew-kata-token
    - source: salt://kiro/crew/kata/files/kirocrew-kata-token
    - template: jinja
    - user: root
    - group: root
    - mode: '0755'
    - context:
        namespace: {{ kata.namespace }}
        container: {{ kata.container }}
        service: {{ kata.service }}
        port: {{ kata.port }}
        host_ip: {{ kata.host_ip }}
        default_ttl: {{ kata.token_ttl }}

# Dedicated CNI network (bridge + IPAM + portmap) so the dashboard port can be
# published from the guest to the host. nerdctl writes a proper conflist under
# /etc/cni/net.d that includes the portmap chain.
kirocrew-kata-network:
  cmd.run:
    - name: nerdctl --namespace {{ kata.namespace }} network create {{ kata.network }} --subnet {{ kata.subnet }}
    - unless: nerdctl --namespace {{ kata.namespace }} network inspect {{ kata.network }}
    - require:
      - sls: containerd.nerdctl

# Pre-pull the image into the containerd namespace so the service starts fast
# and fails early if the image is unavailable.
kirocrew-kata-image:
  cmd.run:
    - name: nerdctl --namespace {{ kata.namespace }} pull {{ kata.image }}
    - unless: nerdctl --namespace {{ kata.namespace }} image inspect {{ kata.image }}
    - require:
      - sls: kata-containers.kata-containers
      - sls: containerd.nerdctl

kirocrew-kata-service-file:
  file.managed:
    - name: /etc/systemd/system/{{ kata.service }}.service
    - user: root
    - group: root
    - mode: '0644'
    - contents: |
        [Unit]
        Description=KiroCrew (Kata Containers / Cloud Hypervisor)
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
          --network {{ kata.network }} \
          --ip {{ kata.container_ip }} \
          --volume {{ kata.home_dir }}:{{ kata.home_mount }} \
          {%- for mount in kata.mounts %}
          --volume {{ mount.source }}:{{ mount.target }}{{ ':ro' if mount.get('read_only', false) else '' }} \
          {%- endfor %}
          {{ kata.image }}
        ExecStop=-/usr/local/bin/nerdctl --namespace {{ kata.namespace }} stop {{ kata.container }}
        Restart=always
        RestartSec=5
        KillMode=mixed

        [Install]
        WantedBy=multi-user.target
    - require:
      {%- for mount in kata.mounts %}
      {%- if not mount.get('read_only', false) %}
      - file: kirocrew-kata-mount-{{ loop.index0 }}
      {%- endif %}
      {%- endfor %}
      - file: kirocrew-kata-home-directory
      - cmd: kirocrew-kata-image
      - cmd: kirocrew-kata-network

kirocrew-kata:
  service.running:
    - name: {{ kata.service }}
    - enable: true
    - require:
      - sls: kata-containers.kata-containers
      - sls: containerd.nerdctl
      - file: kirocrew-kata-service-file
    - watch:
      - file: kirocrew-kata-service-file

# --- Host-side port forwarding so WSL2 mirrors the dashboard to Windows ---
# A systemd .socket opens a REAL listening socket on host_ip:port (which WSL2's
# localhost-forwarding detects and mirrors to Windows), and systemd-socket-
# proxyd forwards accepted connections into the Kata container at its fixed IP.
# This gives Windows access while keeping full Kata VM isolation.

kirocrew-kata-proxy-socket-file:
  file.managed:
    - name: /etc/systemd/system/{{ kata.proxy_service }}.socket
    - user: root
    - group: root
    - mode: '0644'
    - contents: |
        [Unit]
        Description=KiroCrew Kata dashboard proxy socket

        [Socket]
        ListenStream={{ kata.host_ip }}:{{ kata.port }}

        [Install]
        WantedBy=sockets.target

kirocrew-kata-proxy-service-file:
  file.managed:
    - name: /etc/systemd/system/{{ kata.proxy_service }}.service
    - user: root
    - group: root
    - mode: '0644'
    - contents: |
        [Unit]
        Description=KiroCrew Kata dashboard proxy
        Requires={{ kata.proxy_service }}.socket
        After={{ kata.proxy_service }}.socket {{ kata.service }}.service
        BindsTo={{ kata.service }}.service

        [Service]
        ExecStart=/lib/systemd/systemd-socket-proxyd {{ kata.container_ip }}:{{ kata.port }}
    - require:
      - file: kirocrew-kata-proxy-socket-file

kirocrew-kata-proxy-socket:
  service.running:
    - name: {{ kata.proxy_service }}.socket
    - enable: true
    - require:
      - service: kirocrew-kata
      - file: kirocrew-kata-proxy-service-file
    - watch:
      - file: kirocrew-kata-proxy-socket-file
      - file: kirocrew-kata-proxy-service-file
