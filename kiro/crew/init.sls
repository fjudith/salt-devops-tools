{% from tpldir ~ "/map.jinja" import kirocrew with context %}

include:
  - .install
  {%- if kirocrew.enabled and kirocrew.service.enabled and kirocrew.service.mode == 'native' %}
  - .service
  - .docker.teardown
  - .kata.teardown
  {%- elif kirocrew.enabled and kirocrew.service.enabled and kirocrew.service.mode == 'docker' %}
  - .docker.service
  {%- if kirocrew.service.voice.enabled %}
  - .docker.voice
  {%- endif %}
  - .teardown
  - .kata.teardown
  {%- elif kirocrew.enabled and kirocrew.service.enabled and kirocrew.service.mode == 'kata' %}
  - kata-containers.kata-containers
  - containerd.nerdctl
  - .kata.service
  {%- if kirocrew.service.voice.enabled %}
  - .kata.voice
  {%- endif %}
  - .teardown
  - .docker.teardown
  {%- else %}
  - .teardown
  - .docker.teardown
  - .kata.teardown
  {% endif %}
