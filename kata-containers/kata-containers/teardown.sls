# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import kata_containers with context %}

# Remove the kata-clh runtime registration from containerd.
kata-containers-containerd-runtime-teardown:
  file.blockreplace:
    - name: {{ kata_containers.containerd_config }}
    - marker_start: '# BEGIN salt-managed kata-clh runtime'
    - marker_end: '# END salt-managed kata-clh runtime'
    - content: ''
    - append_if_not_found: false
    - onlyif: test -f {{ kata_containers.containerd_config }}

kata-containers-shim-wrapper-teardown:
  file.absent:
    - name: {{ kata_containers.shim_wrapper }}

kata-containers-symlinks-teardown:
  file.absent:
    - names:
      - /usr/local/bin/kata-runtime
      - /usr/local/bin/containerd-shim-kata-v2

kata-containers-install-teardown:
  file.absent:
    - name: {{ kata_containers.install_dir }}
