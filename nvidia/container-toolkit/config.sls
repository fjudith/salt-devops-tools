# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import container_toolkit with context %}

include:
  - .install

{% if container_toolkit.configure_containerd %}
# Register the `nvidia` runtime with containerd so nerdctl/ctr can request GPUs
# (e.g. `nerdctl run --gpus all`). nvidia-ctk edits the containerd config in
# place; containerd's config is otherwise block-managed by the kata formula, so
# this out-of-band edit has a lower drift risk than editing docker's daemon.json
# (which the docker formula manages declaratively).
nvidia-container-toolkit-containerd:
  cmd.run:
    - name: nvidia-ctk runtime configure --runtime=containerd --config={{ container_toolkit.containerd_config }}
    - onlyif: test -f {{ container_toolkit.containerd_config }}
    - unless: grep -q '"nvidia"' {{ container_toolkit.containerd_config }} || grep -q 'runtimes.nvidia' {{ container_toolkit.containerd_config }}
    - require:
      - pkg: nvidia-container-toolkit

nvidia-container-toolkit-containerd-restart:
  service.running:
    - name: containerd
    - watch:
      - cmd: nvidia-container-toolkit-containerd
{% endif %}
