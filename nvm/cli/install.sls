# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import nvm with context %}

nvm-install-dir:
  file.directory:
    - name: {{ nvm.install_dir }}/{{ nvm.version }}
    - user: root
    - group: root
    - mode: '0755'
    - makedirs: true

nvm-script:
  file.managed:
    - name: {{ nvm.install_dir }}/{{ nvm.version }}/nvm.sh
    - source: {{ nvm.base_url }}/v{{ nvm.version }}/nvm.sh
    - skip_verify: true
    - user: root
    - group: root
    - mode: '0644'
    - require:
      - file: nvm-install-dir
    - unless: test -f {{ nvm.install_dir }}/{{ nvm.version }}/nvm.sh

nvm-bash-completion:
  file.managed:
    - name: {{ nvm.install_dir }}/{{ nvm.version }}/bash_completion
    - source: {{ nvm.base_url }}/v{{ nvm.version }}/bash_completion
    - skip_verify: true
    - user: root
    - group: root
    - mode: '0644'
    - require:
      - file: nvm-install-dir
    - unless: test -f {{ nvm.install_dir }}/{{ nvm.version }}/bash_completion

nvm-profile:
  file.managed:
    - name: /etc/profile.d/nvm.sh
    - user: root
    - group: root
    - mode: '0644'
    - contents: |
        # Managed by Salt
        export NVM_DIR="{{ nvm.install_dir }}/{{ nvm.version }}"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
