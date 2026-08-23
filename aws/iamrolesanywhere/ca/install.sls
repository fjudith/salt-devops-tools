# -*- coding: utf-8 -*-
# vim: ft=jinja

{% from tpldir ~ "/map.jinja" import ira with context %}

# Ensure the x509 dependencies are available
rolesanywhere-ca-prereqs:
  pkg.installed:
    - pkgs:
      - python3-cryptography

# CA directory structure
rolesanywhere-ca-dir:
  file.directory:
    - name: {{ ira.ca_dir }}
    - user: root
    - group: root
    - mode: '0755'
    - makedirs: true

rolesanywhere-ca-private-dir:
  file.directory:
    - name: {{ ira.ca_dir }}/private
    - user: root
    - group: root
    - mode: '0750'
    - require:
      - file: rolesanywhere-ca-dir

rolesanywhere-ca-certs-dir:
  file.directory:
    - name: {{ ira.ca_dir }}/certs
    - user: root
    - group: root
    - mode: '0755'
    - require:
      - file: rolesanywhere-ca-dir

# Generate CA private key
rolesanywhere-ca-key:
  x509.private_key_managed:
    - name: {{ ira.ca_dir }}/private/ca.key
    - algo: rsa
    - keysize: {{ ira.ca_key.bits }}
    - require:
      - file: rolesanywhere-ca-private-dir
      - pkg: rolesanywhere-ca-prereqs

# Generate self-signed CA certificate
rolesanywhere-ca-cert:
  x509.certificate_managed:
    - name: {{ ira.ca_dir }}/certs/ca.pem
    - signing_private_key: {{ ira.ca_dir }}/private/ca.key
    - CN: {{ ira.ca_cert.cn }}
    - O: {{ ira.ca_cert.O }}
    - OU: {{ ira.ca_cert.OU }}
    - C: {{ ira.ca_cert.C }}
    - ST: {{ ira.ca_cert.ST }}
    - L: {{ ira.ca_cert.L }}
    - basicConstraints: "critical, CA:true"
    - keyUsage: "critical, keyCertSign, cRLSign"
    - subjectKeyIdentifier: hash
    - authorityKeyIdentifier: keyid:always,issuer
    - days_valid: {{ ira.ca_cert.days_valid }}
    - days_remaining: {{ ira.ca_cert.days_remaining }}
    - require:
      - x509: rolesanywhere-ca-key

# Issue end-entity certificates for workloads
{%- for cert_name, cert_config in ira.certificates.items() %}

rolesanywhere-cert-{{ cert_name }}-key:
  x509.private_key_managed:
    - name: {{ ira.ca_dir }}/private/{{ cert_name }}.key
    - algo: rsa
    - keysize: {{ cert_config.get('bits', 2048) }}
    - require:
      - file: rolesanywhere-ca-private-dir
      - pkg: rolesanywhere-ca-prereqs

rolesanywhere-cert-{{ cert_name }}:
  x509.certificate_managed:
    - name: {{ ira.ca_dir }}/certs/{{ cert_name }}.pem
    - signing_private_key: {{ ira.ca_dir }}/private/ca.key
    - signing_cert: {{ ira.ca_dir }}/certs/ca.pem
    - private_key: {{ ira.ca_dir }}/private/{{ cert_name }}.key
    - CN: {{ cert_config.cn }}
    {%- if cert_config.get('O') %}
    - O: {{ cert_config.O }}
    {%- else %}
    - O: {{ ira.ca_cert.O }}
    {%- endif %}
    {%- if cert_config.get('OU') %}
    - OU: {{ cert_config.OU }}
    {%- else %}
    - OU: {{ ira.ca_cert.OU }}
    {%- endif %}
    - basicConstraints: "critical, CA:false"
    - keyUsage: "critical, digitalSignature, keyEncipherment"
    - extendedKeyUsage: clientAuth
    - subjectKeyIdentifier: hash
    - authorityKeyIdentifier: keyid:always,issuer
    - days_valid: {{ cert_config.get('days_valid', 365) }}
    - days_remaining: {{ cert_config.get('days_remaining', 30) }}
    - require:
      - x509: rolesanywhere-ca-cert
      - x509: rolesanywhere-cert-{{ cert_name }}-key

{%- endfor %}
