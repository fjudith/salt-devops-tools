# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import agentgateway with context %}

{% set ira = agentgateway.iam_roles_anywhere %}
{% set certs_dir = '/home/' ~ agentgateway.user ~ '/.config/agentgateway/certs' %}
{% set certificate_path = certs_dir ~ '/' ~ ira.certificate.cn ~ '.pem' %}
{% set private_key_path = certs_dir ~ '/' ~ ira.certificate.cn ~ '.key' %}

{% if ira.enabled %}

# --- Certificate generation for agentgateway ---

agentgateway-ira-prereqs:
  pkg.installed:
    - pkgs:
      - python3-cryptography

# Certs directory next to the agentgateway config
agentgateway-ira-certs-dir:
  file.directory:
    - name: {{ certs_dir }}
    - user: {{ agentgateway.user }}
    - group: {{ agentgateway.group }}
    - mode: '0750'
    - makedirs: true

agentgateway-ira-key:
  x509.private_key_managed:
    - name: {{ private_key_path }}
    - algo: rsa
    - keysize: {{ ira.certificate.bits }}
    - user: {{ agentgateway.user }}
    - group: {{ agentgateway.group }}
    - mode: '0600'
    - require:
      - pkg: agentgateway-ira-prereqs
      - file: agentgateway-ira-certs-dir

agentgateway-ira-cert:
  x509.certificate_managed:
    - name: {{ certificate_path }}
    - signing_private_key: {{ ira.ca_dir }}/private/ca.key
    - signing_cert: {{ ira.ca_dir }}/certs/ca.pem
    - private_key: {{ private_key_path }}
    - CN: {{ ira.certificate.cn }}
    - basicConstraints: "critical, CA:false"
    - keyUsage: "critical, digitalSignature, keyEncipherment"
    - extendedKeyUsage: clientAuth
    - subjectKeyIdentifier: hash
    - authorityKeyIdentifier: keyid:always,issuer
    - days_valid: {{ ira.certificate.days_valid }}
    - days_remaining: {{ ira.certificate.days_remaining }}
    - user: {{ agentgateway.user }}
    - group: {{ agentgateway.group }}
    - mode: '0644'
    - require:
      - x509: agentgateway-ira-key

# --- Credential server (aws_signing_helper serve) ---
# Agentgateway's Rust AWS SDK does not support credential_process.
# Instead, run aws_signing_helper as a local IMDSv2-compatible credential server
# and point agentgateway to it via AWS_CONTAINER_CREDENTIALS_FULL_URI.

agentgateway-credentials-service-unit:
  file.managed:
    - name: /etc/systemd/system/agentgateway-credentials.service
    - source: salt://agentgateway/files/agentgateway-credentials.service
    - user: root
    - group: root
    - mode: '0644'
    - template: jinja
    - defaults:
        user: {{ agentgateway.user }}
        group: {{ agentgateway.group }}
        certificate_path: {{ certificate_path }}
        private_key_path: {{ private_key_path }}
        trust_anchor_arn: {{ ira.trust_anchor_arn }}
        profile_arn: {{ ira.profile_arn }}
        role_arn: {{ ira.role_arn }}
        region: {{ ira.region }}
        port: {{ ira.credential_server_port }}
    - require:
      - x509: agentgateway-ira-cert

agentgateway-credentials-service:
  service.running:
    - name: agentgateway-credentials
    - enable: true
    - watch:
      - file: agentgateway-credentials-service-unit
      - x509: agentgateway-ira-cert
    - require:
      - file: agentgateway-credentials-service-unit

{% else %}

agentgateway-credentials-service-dead:
  service.dead:
    - name: agentgateway-credentials
    - enable: false
    - onlyif: systemctl is-active agentgateway-credentials

agentgateway-credentials-unit-absent:
  file.absent:
    - name: /etc/systemd/system/agentgateway-credentials.service

{% endif %}
