# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import common with context %}

{% set repoState = 'removed' %}
{% if common.enabled %}
  {% set repoState = 'installed' %}
{% endif %}


common-packages:
  pkg.{{ repoState }}:
    - skip_suggestions: True
    - refresh: True
    - allow_updates: True
    - pkgs:
      {%- for item in common.common %}
      - {{ item }}
      {% endfor %}

{% if common.enabled %}
cni-default-config:
  file.managed:
    - name: /etc/cni/net.d/99-default.conf
    - makedirs: True
    - contents: |
        {
          "cniVersion": "0.3.1",
          "name": "default",
          "plugins": [
            {
              "type": "bridge"
            },
            {
              "type": "portmap",
              "capabilities": {
                "portMappings": true
              }
            },
            {
              "type": "loopback"
            }
          ]
        }
{% else %}
cni-default-config:
  file.absent:
    - name: /etc/cni/net.d/99-default.conf
{% endif %}

{%- if common.enabled %}
{#- The distro packages CNI plugins outside the /opt/cni/bin path that
    containerd, ctr and nerdctl look in by default. Symlink the standard path
    to the packaged location so those tools can find the plugins. #}
{%- set cni_plugin_dirs = {
      'debian': '/usr/lib/cni',
      'redhat': '/usr/libexec/cni',
} %}
{%- set cni_plugin_dir = cni_plugin_dirs.get(grains['os_family']|lower, '/usr/lib/cni') %}
cni-plugin-bin-path:
  file.symlink:
    - name: /opt/cni/bin
    - target: {{ cni_plugin_dir }}
    - force: true
    - makedirs: true
    - onlyif: test -d {{ cni_plugin_dir }}
{% endif %}

{%- if grains['os_family']|lower in ('debian',) %}
debian-packages:
  pkg.{{ repoState }}:
    - skip_suggestions: True
    - refresh: True
    - allow_updates: True
    - pkgs:
      {%- for item in common.debian %}
      - {{ item }}
      {% endfor %}
{% endif %}

{%- if grains['os_family']|lower in ('redhat',) %}
redhat-packages:
  pkg.{{ repoState }}:
    - skip_suggestions: True
    - refresh: True
    - allow_updates: True
    - pkgs:
      {%- for item in common.redhat %}
      - {{ item }}
      {% endfor %}
{% endif %}

{%- if common.virtio.enabled %}
{#- Only manage modules that exist as loadable .ko files on the running kernel.
    Built-in modules (modinfo reports "(builtin)") and modules absent from this
    kernel (e.g. WSL2, cloud-optimized kernels) are skipped, since kmod.present
    cannot load them and would fail on subsequent runs. #}
{%- for mod in common.virtio.modules %}
{%- set modfile = salt['cmd.run']('modinfo -F filename ' ~ mod ~ ' 2>/dev/null', python_shell=True) %}
{%- if modfile and modfile != '(builtin)' %}
virtio-module-{{ mod }}:
  kmod.present:
    - name: {{ mod }}
    - persist: True
{% endif %}
{%- endfor %}
{% else %}
{%- for mod in common.virtio.modules %}
{%- set modfile = salt['cmd.run']('modinfo -F filename ' ~ mod ~ ' 2>/dev/null', python_shell=True) %}
{%- if modfile and modfile != '(builtin)' %}
virtio-module-{{ mod }}:
  kmod.absent:
    - name: {{ mod }}
    - persist: True
{% endif %}
{%- endfor %}
{% endif %}

{%- if common.vfio.enabled %}
{#- Same builtin/absent guard as virtio: only manage modules that exist as
    loadable .ko files on the running kernel. Built-in or absent modules (e.g.
    on WSL2) are skipped. #}
{%- for mod in common.vfio.modules %}
{%- set modfile = salt['cmd.run']('modinfo -F filename ' ~ mod ~ ' 2>/dev/null', python_shell=True) %}
{%- if modfile and modfile != '(builtin)' %}
vfio-module-{{ mod }}:
  kmod.present:
    - name: {{ mod }}
    - persist: True
{% endif %}
{%- endfor %}
{% else %}
{%- for mod in common.vfio.modules %}
{%- set modfile = salt['cmd.run']('modinfo -F filename ' ~ mod ~ ' 2>/dev/null', python_shell=True) %}
{%- if modfile and modfile != '(builtin)' %}
vfio-module-{{ mod }}:
  kmod.absent:
    - name: {{ mod }}
    - persist: True
{% endif %}
{%- endfor %}
{% endif %}

fs.inotify.max_user_watches:
  sysctl.present:
    - value: 1048576

fs.inotify.max_user_instances:
  sysctl.present:
    - value: 512
