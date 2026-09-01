# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import githubcopilot with context %}

githubcopilot-remove:
  file.absent:
    - names:
      - {{ githubcopilot.app_path }}
      - {{ githubcopilot.launcher }}
      - /usr/share/applications/github-copilot.desktop
      - {{ githubcopilot.install_dir }}
