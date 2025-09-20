# Curated Proxy Guide for Dependency Management

## Overview
This guide outlines the implementation of a curated proxy for language packages to enhance security, reliability, and control over dependencies in the Cwork project.

## Benefits of Using a Curated Proxy
- **Security**: Scan and vet all dependencies before they enter the environment
- **Reliability**: Ensure consistent availability and avoid public registry outages
- **Compliance**: Meet regulatory requirements for software provenance
- **Performance**: Cache dependencies locally for faster builds
- **Control**: Manage approved versions and prevent unwanted updates

## Recommended Solutions
1. **JFrog Artifactory** - Enterprise-grade artifact management
2. **Sonatype Nexus Repository** - Popular open-source and commercial option
3. **GitHub Packages** - Integrated with GitHub ecosystem
4. **Verdaccio** - Lightweight, self-hosted npm registry

## Implementation Plan

### Phase 1: Evaluation (Current)
- Assess current dependency usage patterns
- Evaluate proxy solutions based on project needs
- Estimate costs and resource requirements

### Phase 2: Pilot Implementation
- Set up development instance of chosen proxy
- Configure for npm packages initially
- Test with isolated services

### Phase 3: Full Deployment
- Migrate all services to use curated proxy
- Configure CI/CD pipelines to use proxy
- Implement access controls and auditing

## Configuration Examples

### npm Configuration
```bash
# Set registry for a project
npm config set registry https://your-proxy-domain.com/repository/npm-group/

# Or use per-project .npmrc
echo "registry=https://your-proxy-domain.com/repository/npm-group/" > .npmrc
echo "always-auth=true" >> .npmrc
```

### Docker Configuration
```dockerfile
# Use curated proxy for npm installs
RUN npm config set registry https://your-proxy-domain.com/repository/npm-group/ \
    && npm install
```

### GitHub Actions Workflow
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'
          registry-url: 'https://your-proxy-domain.com/repository/npm-group/'
      - name: Install dependencies
        run: npm ci
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_PROXY_TOKEN }}
```

## Service-Specific Configuration

### Backend Services (auth-service, marketplace-service)
```bash
# Create .npmrc in each service directory
echo "registry=https://your-proxy-domain.com/repository/npm-group/" > backend/auth-service/.npmrc
echo "registry=https://your-proxy-domain.com/repository/npm-group/" > backend/marketplace-service/.npmrc
```

### Contracts Project
```bash
# Hardhat configuration may need additional setup
echo "registry=https://your-proxy-domain.com/repository/npm-group/" > contracts/.npmrc
```

### Mobile App
```bash
# Flutter/Dart may require different approach
# For npm dependencies in mobile app
echo "registry=https://your-proxy-domain.com/repository/npm-group/" > mobile-app/.npmrc
```

## Security Considerations

1. **Authentication**: Use tokens or credentials for proxy access
2. **Access Control**: Restrict who can publish and pull packages
3. **Scanning**: Integrate vulnerability scanning in the proxy
4. **Auditing**: Maintain logs of all package requests and downloads
5. **Backup**: Regular backups of the proxy repository

## Migration Checklist

- [ ] Evaluate and select proxy solution
- [ ] Set up proxy infrastructure
- [ ] Configure authentication and access controls
- [ ] Test with sample projects
- [ ] Update CI/CD pipelines to use proxy
- [ ] Migrate development environments
- [ ] Update documentation and runbooks
- [ ] Train development team on new workflow

## Emergency Procedures

### Fallback to Public Registry
```bash
# Temporary override for emergency situations
npm install --registry https://registry.npmjs.org
```

### Proxy Outage Response
1. Check proxy health status
2. Switch to public registry temporarily
3. Investigate and resolve proxy issues
4. Return to curated proxy once resolved

## Monitoring and Maintenance

- Monitor proxy performance and storage usage
- Regular updates and patches for proxy software
- Review access logs for suspicious activity
- Periodic audit of allowed dependencies
- Update vulnerability databases regularly

## Next Steps

1. **Immediate**: Research and select a proxy solution
2. **Short-term**: Set up development instance for testing
3. **Medium-term**: Configure CI/CD pipelines to use proxy
4. **Long-term**: Full migration and decommission of public registry access

## Resources
- [JFrog Artifactory Documentation](https://www.jfrog.com/confluence/)
- [Sonatype Nexus Documentation](https://help.sonatype.com/repomanager3)
- [GitHub Packages Guide](https://docs.github.com/en/packages)
- [Verdaccio Documentation](https://verdaccio.org/docs/en/)