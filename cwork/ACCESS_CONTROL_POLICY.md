# Access Control Policy and RBAC Implementation

## Overview
This document outlines the Role-Based Access Control (RBAC) policy for the Cwork project across all platforms and services. It defines roles, permissions, and enforcement mechanisms to ensure least privilege access.

## Platforms Requiring Access Control

### 1. GitHub Organization
**Current State:** Repository access managed through team memberships
**Target State:** Structured RBAC with defined roles

#### Roles and Permissions:
- **Admin**: Full repository access, branch protection management, secrets management
- **Maintainer**: Push access to main branches, merge pull requests, manage issues
- **Developer**: Read access, create branches, submit pull requests
- **Read-only**: View access for stakeholders and auditors

#### Enforcement:
```yaml
# .github/teams.yml (to be created)
teams:
  admins:
    members: [user1, user2]
    permissions: admin
  maintainers:
    members: [user3, user4]
    permissions: maintain
  developers:
    members: [user5, user6]
    permissions: push
```

### 2. HashiCorp Vault
**Current State:** Basic policies defined in SECRETS_MANAGEMENT.md
**Target State:** Granular RBAC with service-specific policies

#### Enhanced Policies:
```hcl
# backend-developer-policy.hcl
path "secret/data/backend/*" {
  capabilities = ["read"]
}

path "secret/metadata/backend/*" {
  capabilities = ["list"]
}

# ci-bot-policy.hcl  
path "secret/data/cicd/*" {
  capabilities = ["read"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}
```

### 3. Database Access (PostgreSQL)
**Current State:** Shared credentials in environment variables
**Target State:** Per-service database users with limited privileges

#### Database Roles:
- **auth_service**: SELECT, INSERT, UPDATE, DELETE on auth tables only
- **marketplace_service**: SELECT, INSERT, UPDATE, DELETE on marketplace tables only
- **readonly_user**: SELECT on all tables for reporting
- **migration_user**: DDL privileges for schema changes

### 4. Cloud Services (If applicable)
**AWS/GCP/Azure RBAC policies to be defined based on deployment environment**

## 2FA Enforcement Plan

### GitHub 2FA Enforcement
```yaml
# .github/security.yml
require_two_factor_authentication: true
require_signed_commits: true
allowed_actions: local_only
```

### Vault 2FA Configuration
```bash
# Enable MFA for userpass auth method
vault auth enable -path=userpass-mfa userpass

# Configure MFA
vault write auth/userpass-mfa/mfa_config type=totp
```

### Internal Systems 2FA
- VPN access requiring 2FA
- SSH key-based authentication with 2FA for bastion hosts
- Admin consoles protected by 2FA

## API Key and Credential Rotation

### Inventory of Current Credentials
1. **GitHub Personal Access Tokens**
2. **npm tokens** 
3. **Docker Hub credentials**
4. **Cloud provider access keys**
5. **Database credentials**
6. **Third-party service API keys**

### Rotation Schedule
- **Critical secrets**: Rotate every 90 days (database passwords, JWT secrets)
- **CI/CD tokens**: Rotate every 180 days  
- **User access tokens**: Rotate annually or on employee departure
- **Emergency rotation**: Immediately upon suspected compromise

### Rotation Procedure
```bash
#!/bin/bash
# scripts/rotate-credentials.sh
# Automated credential rotation script
vault kv patch secret/backend/auth db_pass=$(generate_password)
vault kv patch secret/cicd/common npm_token=$(generate_token)
# Notify services to reload secrets
```

## Implementation Timeline

### Phase 1: Assessment (Week 1)
- [ ] Audit current access levels across all platforms
- [ ] Inventory all API keys and credentials
- [ ] Document current 2FA status for all accounts

### Phase 2: Policy Definition (Week 2)
- [ ] Finalize RBAC roles and permissions matrix
- [ ] Create GitHub teams configuration
- [ ] Define Vault policy enhancements
- [ ] Establish database user roles

### Phase 3: Enforcement (Week 3)
- [ ] Implement GitHub team structures
- [ ] Configure Vault RBAC policies
- [ ] Set up database role-based access
- [ ] Enforce 2FA across all platforms

### Phase 4: Rotation (Week 4)
- [ ] Rotate all existing credentials
- [ ] Implement automated rotation schedules
- [ ] Update documentation and runbooks

## Monitoring and Auditing

### Access Logging
- GitHub audit log monitoring
- Vault access logging to SIEM
- Database query logging
- Cloud trail/audit log aggregation

### Alerting
- Unusual access patterns
- Failed authentication attempts
- Permission escalation attempts
- Credential usage outside expected patterns

## Emergency Procedures

### Access Revocation
1. Immediate revocation of compromised credentials
2. Notification of affected services
3. Investigation of access patterns
4. Root cause analysis and remediation

### Breach Response
1. Isolate affected systems
2. Rotate all potentially compromised credentials
3. Conduct forensic analysis
4. Implement additional security controls

## References
- [GitHub Organization RBAC](https://docs.github.com/en/organizations)
- [Vault Policies Documentation](https://www.vaultproject.io/docs/concepts/policies)
- [NIST RBAC Guidelines](https://csrc.nist.gov/projects/role-based-access-control)