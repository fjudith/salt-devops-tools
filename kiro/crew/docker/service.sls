# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from "kiro/crew/map.jinja" import kirocrew with context %}

{% set docker = kirocrew.service.docker %}

kirocrew-docker-seccomp:
  file.managed:
    - name: {{ docker.seccomp_profile }}
    - source: {{ docker.seccomp_url }}
    - user: root
    - group: root
    - mode: '0644'
    - makedirs: true
    - skip_verify: true

kirocrew-docker-image:
  cmd.run:
    - name: docker pull {{ docker.image }}
    - require:
      - file: kirocrew-docker-seccomp

kirocrew-docker-volume:
  cmd.run:
    - name: docker volume create {{ docker.volume }}
    - unless: docker volume inspect {{ docker.volume }}

{% if docker.userns_host %}
# With --userns=host the container writes the home volume as host uid {{ docker.uid }}.
# Ensure the volume is owned by that uid so the container can write it,
# regardless of what uid previously populated it (e.g. a userns-remapped run).
# Chown is done on the host (as root) against the volume mountpoint, because a
# container running as uid {{ docker.uid }} cannot even read a 0700 dir owned by
# a different (remapped) uid to chown it itself.
kirocrew-docker-home-ownership:
  cmd.run:
    - name: chown -R {{ docker.uid }}:{{ docker.gid }} "$(docker volume inspect --format '{{ '{{' }}.Mountpoint{{ '}}' }}' {{ docker.volume }})"
    - unless: test "$(stat -c '%u' "$(docker volume inspect --format '{{ '{{' }}.Mountpoint{{ '}}' }}' {{ docker.volume }})")" = "{{ docker.uid }}"
    - require:
      - cmd: kirocrew-docker-volume
{% endif %}

{% for mount in docker.mounts %}
{% if not mount.get('read_only', false) %}
# Read-write bind-mount source, created on the host and owned by the container
# uid so it can create entries at the top level. With --userns=host that maps
# to the same uid on the host. Read-only sources (e.g. ~/.aws) are left as-is.
kirocrew-docker-mount-{{ loop.index0 }}:
  file.directory:
    - name: {{ mount.source }}
    - user: {{ docker.uid }}
    - group: {{ docker.gid }}
    - makedirs: true
{% endif %}
{% endfor %}

# One-time interactive login helper. kiro-cli login is an interactive OAuth
# flow, so it cannot run inside a state apply; this drops a helper on PATH that
# runs the login against the same home volume the service uses.
# Run `sudo kirocrew-docker-login`.
kirocrew-docker-login-helper:
  file.managed:
    - name: /usr/local/bin/kirocrew-docker-login
    - source: salt://kiro/crew/docker/files/kirocrew-docker-login
    - template: jinja
    - user: root
    - group: root
    - mode: '0755'
    - context:
        image: {{ docker.image }}
        volume: {{ docker.volume }}
        service: {{ docker.service }}
        container: {{ docker.container }}
        userns_host: {{ docker.userns_host }}

# Helper that prints a dashboard access URL + token from the running container.
# Run `sudo kirocrew-docker-token [TTL]`.
kirocrew-docker-token-helper:
  file.managed:
    - name: /usr/local/bin/kirocrew-docker-token
    - source: salt://kiro/crew/docker/files/kirocrew-docker-token
    - template: jinja
    - user: root
    - group: root
    - mode: '0755'
    - context:
        container: {{ docker.container }}
        service: {{ docker.service }}
        port: {{ docker.port }}
        host_ip: {{ docker.host_ip }}
        default_ttl: {{ docker.token_ttl }}

kirocrew-docker-service-file:
  file.managed:
    - name: /etc/systemd/system/{{ docker.service }}.service
    - user: root
    - group: root
    - mode: '0644'
    - contents: |
        [Unit]
        Description=KiroCrew (Docker)
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
          {%- if docker.userns_host %}
          --userns=host \
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
          --publish {{ docker.host_ip }}:{{ docker.port }}:5476 \
          --volume {{ docker.volume }}:/home/kirocrew \
          {%- for mount in docker.mounts %}
          --volume {{ mount.source }}:{{ mount.target }}{{ ':ro' if mount.get('read_only', false) else '' }} \
          {%- endfor %}
          --security-opt seccomp={{ docker.seccomp_profile }} \
          {{ docker.image }}
        ExecStop=-/usr/bin/docker stop {{ docker.container }}
        Restart=always
        RestartSec=5
        KillMode=mixed

        [Install]
        WantedBy=multi-user.target
    - require:
      - file: kirocrew-docker-seccomp
      - cmd: kirocrew-docker-image
      - cmd: kirocrew-docker-volume
      {%- if docker.userns_host %}
      - cmd: kirocrew-docker-home-ownership
      {%- endif %}
      {%- for mount in docker.mounts %}
      {%- if not mount.get('read_only', false) %}
      - file: kirocrew-docker-mount-{{ loop.index0 }}
      {%- endif %}
      {%- endfor %}

kirocrew-docker:
  service.running:
    - name: {{ docker.service }}
    - enable: true
    - require:
      - file: kirocrew-docker-service-file
    - watch:
      - file: kirocrew-docker-service-file
