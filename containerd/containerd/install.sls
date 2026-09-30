# -*- coding: utf-8 -*-
# vim: ft=jinja

{%- from tpldir ~ "/map.jinja" import containerd with context %}

# containerd.io is published in the Docker APT/YUM repository, so the docker
# repo must be configured before this package can be installed.
include:
  - docker.repo

containerd.io:
  pkg.installed:
    - version: '{{ containerd.version }}-1~ubuntu.{{ grains["osrelease"] }}~{{ grains["oscodename"] }}'
    - require:
      - sls: docker.repo
