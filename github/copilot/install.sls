# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import githubcopilot with context %}

githubcopilot-install-dir:
  file.directory:
    - name: {{ githubcopilot.install_dir }}
    - user: root
    - group: root
    - mode: '0755'
    - makedirs: true

githubcopilot-download:
  file.managed:
    - name: {{ githubcopilot.app_path }}
    - source: {{ githubcopilot.source_url }}
    - skip_verify: true
    - user: root
    - group: root
    - mode: '0755'
    - unless: test -x {{ githubcopilot.app_path }}
    - require:
      - file: githubcopilot-install-dir

githubcopilot-bin:
  file.symlink:
    - name: {{ githubcopilot.launcher }}
    - target: {{ githubcopilot.app_path }}
    - force: true
    - require:
      - file: githubcopilot-download

githubcopilot-desktop-entry:
  file.managed:
    - name: /usr/share/applications/github-copilot.desktop
    - contents: |
        [Desktop Entry]
        Type=Application
        Name=GitHub Copilot
        Comment=GitHub Copilot GUI
        Exec={{ githubcopilot.app_path }}
        Icon=github-copilot
        Terminal=false
        Categories=Development;IDE;
        StartupNotify=true
    - user: root
    - group: root
    - mode: '0644'
    - require:
      - file: githubcopilot-download
