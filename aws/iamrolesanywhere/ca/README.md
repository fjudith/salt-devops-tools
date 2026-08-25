# IAM Roles Anywhere CA Formula

Generates a private Certificate Authority and end-entity certificates for use with [AWS IAM Roles Anywhere](https://docs.aws.amazon.com/rolesanywhere/latest/userguide/).

## States

| State | Purpose |
|-------|---------|
| `init.sls` | Entry point — routes to install or teardown |
| `install.sls` | Creates CA key/cert, issues workload certificates |
| `signing-helper.sls` | Installs `aws_signing_helper` binary |
| `teardown.sls` | Removes CA directory and signing helper |

## CloudFormation Stack

A CloudFormation template is provided at `files/cloudformation.yaml` to configure the AWS-side resources:

- **Trust Anchor** — references the CA certificate (PEM)
- **Profile** — links the trust anchor to the IAM role
- **IAM Role** — trusted by `rolesanywhere.amazonaws.com`

### Deploy the stack

1. Generate the CA certificate:

```bash
sudo salt-call --local state.apply aws.iamrolesanywhere.ca
```

2. Retrieve the CA certificate PEM:

```bash
sudo cat /etc/pki/rolesanywhere/certs/ca.pem
```

3. Deploy the CloudFormation stack (stack name includes hostname and trust anchor name):

```bash
aws cloudformation deploy \
  --template-file /srv/salt/aws/iamrolesanywhere/ca/files/cloudformation.yaml \
  --stack-name "iam-roles-anywhere-$(hostname)-workstation-ca" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    TrustAnchorName=$(hostname) \
    RoleName=MyRolesAnywhereRole \
    CACertificatePEM="$(sudo cat /etc/pki/rolesanywhere/certs/ca.pem)" \
    SessionDuration=3600
```

4. Copy the stack outputs into your Salt pillar:

```bash
aws cloudformation describe-stacks --stack-name "iam-roles-anywhere-$(hostname)-workstation-ca" \
  --query 'Stacks[0].Outputs' --output table
```

### Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `TrustAnchorName` | *(required)* | Name for the trust anchor (also used in the stack name) |
| `ProfileName` | `default` | Name for the Roles Anywhere profile |
| `RoleName` | `RolesAnywhereWorkstationRole` | IAM role name |
| `CACertificatePEM` | *(required)* | PEM content of the CA certificate |
| `SessionDuration` | `3600` | Credential validity in seconds (900–43200) |
| `ManagedPolicyArns` | *(empty)* | Comma-separated managed policy ARNs for the role |
| `ConditionSubjectCN` | *(empty)* | Restrict to certificates with this CN |

### Outputs

| Output | Usage |
|--------|-------|
| `TrustAnchorArn` | Pillar `iam_roles_anywhere.trust_anchor_arn` |
| `ProfileArn` | Pillar `iam_roles_anywhere.profile_arn` |
| `RoleArn` | Pillar `iam_roles_anywhere.role_arn` |
| `PillarSnippet` | Ready-to-paste pillar YAML block |

## Pillar Configuration

```yaml
aws:
  iamrolesanywhere:
    ca:
      enabled: true
      ca_cert:
        cn: "IAM Roles Anywhere CA"
        O: "My Organization"
        OU: "Platform Engineering"
        C: "US"
        ST: "California"
        L: "San Francisco"
      certificates:
        agentgateway:
          cn: "agentgateway"
          days_valid: 365
          days_remaining: 30
```

## Apply

```bash
sudo salt-call --local state.apply aws.iamrolesanywhere.ca
```
