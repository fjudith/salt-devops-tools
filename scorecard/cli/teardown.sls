# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import scorecard with context %}

scorecard-archive:
  file.absent:
    - name: /usr/local/scorecard/{{ scorecard.version }}

scorecard:
  file.absent:
    - name: /usr/local/bin/scorecard

scorecard-completion:
  file.absent:
    - name: /etc/bash_completion.d/scorecard
