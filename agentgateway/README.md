# Agentgateway Formula

Installs and configures [Agentgateway](https://agentgateway.dev/) — an AI-native proxy for MCP and A2A protocols.

## States

| State | Purpose |
|-------|---------|
| `init.sls` | Entry point — routes to install/config or teardown |
| `install.sls` | Downloads the binary and symlinks to `/usr/local/bin` |
| `config.sls` | Creates user/group, config file, systemd service unit |
| `aws-iam-roles-anywhere.sls` | Issues X.509 certificate and runs credential server |
| `teardown.sls` | Stops service, removes binary, user, and group |

## Dependencies

When `iam_roles_anywhere.enabled` is `true`, this formula depends on:

| Formula | Purpose |
|---------|---------|
| `aws.iamrolesanywhere.ca` | Provides the CA key and certificate used to sign the agentgateway end-entity certificate |
| `aws.iamrolesanywhere.ca` (signing-helper) | Installs the `aws_signing_helper` binary at `/usr/local/bin/aws_signing_helper` |

Apply the CA formula **before** the agentgateway formula:

```bash
sudo salt-call --local state.apply aws.iamrolesanywhere.ca
sudo salt-call --local state.apply agentgateway
```

Or ensure both are listed in `top.sls` with `aws.iamrolesanywhere.ca` appearing first.

## File Layout

```
/home/<user>/.config/agentgateway/
├── config.yaml                    # Agentgateway configuration
├── aws-config                     # (removed — no longer used)
└── certs/
    ├── <cn>.pem                   # X.509 certificate (IAM Roles Anywhere)
    └── <cn>.key                   # Private key (PKCS#8 PEM)

/etc/systemd/system/agentgateway.service               # Main service unit
/etc/systemd/system/agentgateway-credentials.service   # Credential server sidecar
/usr/local/bin/agentgateway                            # Binary symlink
```

## Pillar Configuration

```yaml
agentgateway:
  enabled: true
  version: 1.4.1
  user: agentgateway
  group: agentgateway
  config:
    admin_addr: 0.0.0.0:15000
    stats_addr: 0.0.0.0:15020
    readiness_addr: 0.0.0.0:15021
  iam_roles_anywhere:
    enabled: true
    profile_name: agentgateway
    trust_anchor_arn: "arn:aws:rolesanywhere:..."
    profile_arn: "arn:aws:rolesanywhere:..."
    role_arn: "arn:aws:iam::...:role/..."
    ca_dir: /etc/pki/rolesanywhere
    credential_server_port: 9911
    certificate:
      cn: "agentgateway"
      bits: 2048
      days_valid: 365
      days_remaining: 30
    region: ca-central-1
```

## IAM Roles Anywhere Credential Flow

Agentgateway's Rust AWS SDK does not support `credential_process` (the cargo feature is not compiled in). Instead, `aws_signing_helper` runs in **serve mode** as a sidecar systemd service, exposing an IMDSv2-compatible credential endpoint on localhost.

```
agentgateway-credentials.service (aws_signing_helper serve :9911)
  └─ Exposes IMDSv2-compatible endpoint at http://127.0.0.1:9911
  └─ On credential request:
       └─ Signs with X.509 cert + private key
       └─ Calls IAM Roles Anywhere CreateSession API
       └─ Returns temporary credentials

agentgateway.service (AWS_EC2_METADATA_SERVICE_ENDPOINT=http://127.0.0.1:9911)
  └─ Requires=agentgateway-credentials.service
  └─ AWS SDK fetches credentials from local IMDSv2 endpoint
  └─ Uses credentials to call AWS services (Bedrock, etc.)
```

### Certificate Paths

Certificate and key paths are derived dynamically from the user and certificate CN:

```
/home/<user>/.config/agentgateway/certs/<cn>.pem
/home/<user>/.config/agentgateway/certs/<cn>.key
```

## Apply

```bash
# If iam_roles_anywhere is enabled, apply the CA formula first
sudo salt-call --local state.apply aws.iamrolesanywhere.ca

# Then apply the agentgateway formula
sudo salt-call --local state.apply agentgateway
```
