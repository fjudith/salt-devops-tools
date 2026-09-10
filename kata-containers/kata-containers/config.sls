# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import kata_containers with context %}

{% set conf_file = kata_containers.install_dir ~ '/share/defaults/kata-containers/configuration-' ~ kata_containers.hypervisor ~ '.toml' %}

include:
  - .install

# Shim wrapper that pins KATA_CONF_FILE to the Cloud Hypervisor (clh) config.
kata-containers-shim-wrapper:
  file.managed:
    - name: {{ kata_containers.shim_wrapper }}
    - source: salt://kata-containers/kata-containers/files/containerd-shim-kata-clh-v2
    - template: jinja
    - user: root
    - group: root
    - mode: '0755'
    - context:
        conf_file: {{ conf_file }}
        install_dir: {{ kata_containers.install_dir }}
    - require:
      - sls: kata-containers.kata-containers.install

# Register the kata-clh runtime handler in containerd. Managed as a marked
# block so it coexists with the rest of the (docker-managed) containerd config.
kata-containers-containerd-runtime:
  file.blockreplace:
    - name: {{ kata_containers.containerd_config }}
    - marker_start: '# BEGIN salt-managed kata-clh runtime'
    - marker_end: '# END salt-managed kata-clh runtime'
    - append_if_not_found: true
    - content: |
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.{{ kata_containers.runtime_name }}]
          runtime_type = "io.containerd.{{ kata_containers.runtime_name }}.v2"
          privileged_without_host_devices = true
          pod_annotations = ["io.katacontainers.*"]
          container_annotations = ["io.katacontainers.*"]
    - require:
      - file: kata-containers-shim-wrapper

kata-containers-containerd-restart:
  service.running:
    - name: containerd
    - watch:
      - file: kata-containers-containerd-runtime
