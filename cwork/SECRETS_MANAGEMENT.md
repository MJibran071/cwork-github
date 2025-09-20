# Secrets Management Implementation Guide

## Overview
This document outlines the secrets management strategy for the Cwork project, integrating HashiCorp Vault for centralized secrets management across all environments and CI/CD pipelines.

## Current Secrets Inventory

### Backend Services
- **Auth Service**: Database credentials, JWT secrets, OAuth credentials
- **Marketplace Service**: Database credentials, API keys, encryption keys

### Contracts
- **Ethereum**: Private keys, Infura/Alchemy API keys
- **Solana**: Private keys, RPC endpoints

### Mobile App
- **API endpoints**, encryption keys, third-party service credentials

### CI/CD
- **Docker Hub credentials**, npm tokens, deployment keys

## HashiCorp Vault Setup

### Vault Server Configuration
```bash
# Install Vault
brew install vault

# Start Vault server in dev mode (for testing)
vault server -dev

# Initialize Vault
vault operator init
```

### Vault Policies
Create policies for different services:

```hcl
# backend-policy.hcl
path "secret/data/backend/*" {
  capabilities = ["read", "list"]
}

# contracts-policy.hcl  
path "secret/data/contracts/*" {
  capabilities = ["read", "list"]
}

# ci-policy.hcl
path "secret/data/cicd/*" {
  capabilities = ["read", "list"]
}
```

### Secrets Engine Setup
```bash
# Enable KV secrets engine
vault secrets enable -path=secret kv-v2

# Create backend secrets
vault kv put secret/backend/auth \
  db_host=localhost \
  db_user=auth_user \
  db_pass=secure_password \
  jwt_secret=super_secret_jwt_key

vault kv put secret/backend/marketplace \
  db_host=localhost \
  db_user=marketplace_user \
  db_pass=another_secure_password \
  stripe_key=sk_test_123

# Create contracts secrets
vault kv put secret/contracts/ethereum \
  private_key=0x123... \
  alchemy_key=alchemy_key_here \
  infura_key=infura_key_here

vault kv put secret/contracts/solana \
  private_key=solana_key_here \
  rpc_endpoint=https://api.mainnet-beta.solana.com

# Create CI/CD secrets
vault kv put secret/cicd/common \
  docker_username=your_username \
  docker_password=your_password \
  npm_token=npm_token_here
```

## CI/CD Integration

### GitHub Actions Vault Integration
Create a Vault authentication method for GitHub Actions:

```bash
# Enable JWT auth method
vault auth enable jwt

# Configure JWT auth for GitHub
vault write auth/jwt/config \
  jwt_validation_pubkeys=@github_public_key.pem \
  bound_issuer="https://token.actions.githubusercontent.com"

# Create role for GitHub Actions
vault write auth/jwt/role/github-actions \
  role_type="jwt" \
  bound_audiences="https://github.com/your-org/your-repo" \
  bound_claims={"ref": "refs/heads/main"} \
  user_claim="actor" \
  policies="ci-policy"
```

### GitHub Actions Workflow Example
```yaml
name: Backend CI with Vault Secrets

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '18'

    - name: Authenticate with Vault
      uses: hashicorp/vault-action@v2
      with:
        url: https://vault.yourcompany.com
        method: jwt
        secrets: |
          secret/data/backend/auth db_host, db_user, db_pass, jwt_secret | authEnv ;
          secret/data/cicd/common npm_token | NPM_TOKEN ;

    - name: Install dependencies
      run: npm ci
      env:
        NPM_TOKEN: ${{ secrets.NPM_TOKEN }}

    - name: Run tests
      run: npm test
      env:
        DB_HOST: ${{ steps.vault.outputs.db_host }}
        DB_USER: ${{ steps.vault.outputs.db_user }}
        DB_PASS: ${{ steps.vault.outputs.db_pass }}
        JWT_SECRET: ${{ steps.vault.outputs.jwt_secret }}
```

## Local Development Setup

### Environment Variables Management
Create a script to pull secrets for local development:

```bash
#!/bin/bash
# scripts/pull-secrets.sh

# Authenticate with Vault (using your preferred method)
export VAULT_TOKEN=$(vault login -method=userpass username=developer -format=json | jq -r .auth.client_token)

# Pull backend secrets
vault kv get -format=json secret/backend/auth | jq -r '.data.data | to_entries | .[] | "export \(.key)=\(.value)"' > .env.vault

# Source the environment variables
source .env.vault
```

### Docker Compose Integration
Update docker-compose.yml to use Vault secrets:

```yaml
version: '3.8'
services:
  auth-service:
    build: ./backend/auth-service
    environment:
      - DB_HOST=${DB_HOST}
      - DB_USER=${DB_USER}
      - DB_PASS=${DB_PASS}
      - JWT_SECRET=${JWT_SECRET}
    depends_on:
      - vault-agent

  vault-agent:
    image: vault:latest
    command: agent -config=/vault/config/agent.hcl
    volumes:
      - ./vault/config:/vault/config
      - ./backend/auth-service:/secrets
```

## Migration Plan

### Phase 1: Assessment
- [ ] Inventory all hardcoded secrets in codebase
- [ ] Identify all environment files and configurations
- [ ] Document current secret usage patterns

### Phase 2: Vault Setup
- [ ] Deploy HashiCorp Vault instance
- [ ] Configure authentication methods
- [ ] Set up secrets engines and policies
- [ ] Migrate existing secrets to Vault

### Phase 3: CI/CD Integration
- [ ] Update GitHub Actions workflows to use Vault
- [ ] Configure Vault authentication for GitHub Actions
- [ ] Test secret retrieval in CI pipelines

### Phase 4: Local Development
- [ ] Create scripts for local secret access
- [ ] Update documentation for developers
- [ ] Train team on new secrets management process

### Phase 5: Monitoring and Rotation
- [ ] Set up secret rotation schedules
- [ ] Implement auditing and monitoring
- [ ] Create emergency rotation procedures

## Security Considerations

- **Least Privilege**: Each service gets only the secrets it needs
- **Rotation**: Secrets are rotated regularly (90 days for critical secrets)
- **Auditing**: All secret access is logged and monitored
- **Backup**: Vault configuration and seals are backed up securely
- **Disaster Recovery**: Procedures for Vault outage scenarios

## Emergency Procedures

### Secret Compromise
1. Immediately rotate compromised secrets in Vault
2. Revoke any associated tokens or credentials
3. Investigate access logs for suspicious activity
4. Notify affected services to reload secrets

### Vault Outage
1. Use sealed backup keys to unseal Vault
2. If unavailable, use emergency procedures with fallback secrets
3. Restore from backup if necessary

## References

- [HashiCorp Vault Documentation](https://www.vaultproject.io/docs)
- [GitHub Actions Vault Integration](https://github.com/hashicorp/vault-action)
- [Vault Best Practices](https://learn.hashicorp.com/collections/vault/best-practices)