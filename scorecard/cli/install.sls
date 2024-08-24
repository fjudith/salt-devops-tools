# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import scorecard with context %}

scorecard-archive:
  archive.extracted:
    - name: /usr/local/scorecard/{{ scorecard.version }}
    - source: https://github.com/ossf/scorecard/releases/download/v{{ scorecard.version }}/scorecard_{{ scorecard.version }}_linux_amd64.tar.gz
    - source_hash: https://github.com/ossf/scorecard/releases/download/v{{ scorecard.version }}/scorecard_checksums.txt
    - user: root
    - group: root
    - archive_format: tar
    - enforce_toplevel: false
    # - options: '--strip-components=1'
    - unless: ls /usr/local/scorecard/{{ scorecard.version }}

scorecard:
  file.symlink:
    - name: /usr/local/bin/scorecard
    - target: /usr/local/scorecard/{{ scorecard.version }}/scorecard
