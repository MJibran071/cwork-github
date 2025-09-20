# Secret Rotation & Rollback Drills

## Overview
This document outlines practical drills for secret rotation and rollback procedures. These drills are designed to ensure the team can efficiently rotate secrets and execute rollbacks under pressure, minimizing downtime and security risks.

## Secret Rotation Drills

### Drill 1: Emergency API Key Rotation

**Scenario:** API key compromise detected
**Objective:** Rotate all production API keys within 30 minutes
**Frequency:** Quarterly

**Steps:**
1. **Detection (Time: 0-5 min)**
   - Receive alert: API key exposed in public repository
   - Verify compromise through access logs

2. **Preparation (Time: 5-10 min)**
   - Inventory all systems using compromised key
   - Prepare new API keys in secure storage
   - Notify dependent teams of impending rotation

3. **Execution (Time: 10-25 min)**
   - Deploy new keys to all systems simultaneously
   - Update configuration files and environment variables
   - Verify new keys are functional
   - Revoke compromised keys immediately

4. **Validation (Time: 25-30 min)**
   - Confirm all systems operational with new keys
   - Monitor for any service disruptions
   - Document rotation completion

**Success Criteria:**
- All keys rotated within time limit
- Zero service interruptions
- Comprehensive documentation

### Drill 2: Database Credential Rotation

**Scenario:** Regular preventive rotation
**Objective:** Rotate database credentials without downtime
**Frequency:** Monthly

**Steps:**
1. **Pre-Rotation Checklist**
   - Verify database replication status
   - Prepare new credentials in vault
   - Schedule during low-traffic periods

2. **Staged Rotation**
   - Update application credentials in batches
   - Monitor connection pools and performance
   - Rotate read replicas first, then primary

3. **Verification**
   - Confirm all applications using new credentials
   - Validate data integrity
   - Monitor for authentication errors

4. **Cleanup**
   - Revoke old credentials
   - Update rotation records
   - Conduct post-rotation review

**Success Criteria:**
- No database connection errors
- Application performance maintained
- All old credentials properly revoked

### Drill 3: SSL/TLS Certificate Rotation

**Scenario:** Certificate expiration approaching
**Objective:** Rotate certificates before expiration
**Frequency:** 60 days before expiration

**Steps:**
1. **Preparation**
   - Generate new certificates
   - Validate certificate chain
   - Prepare deployment packages

2. **Staged Deployment**
   - Deploy to non-critical services first
   - Monitor for certificate validation issues
   - Gradually roll out to all services

3. **Verification**
   - Check SSL handshake success rates
   - Validate certificate trust chains
   - Monitor for security warnings

4. **Documentation**
   - Update certificate expiration tracking
   - Document rotation process
   - Schedule next rotation

## Rollback Drills

### Drill 1: Application Deployment Rollback

**Scenario:** New deployment causing critical errors
**Objective:** Roll back to previous stable version within 15 minutes
**Frequency:** After each major deployment

**Steps:**
1. **Detection (Time: 0-2 min)**
   - Monitor alerts for increased error rates
   - Confirm deployment-related issues

2. **Decision (Time: 2-5 min)**
   - Assess impact severity
   - Make rollback decision
   - Notify stakeholders

3. **Execution (Time: 5-12 min)**
   - Execute automated rollback script
   - Verify previous version deployment
   - Confirm service restoration

4. **Validation (Time: 12-15 min)**
   - Monitor error rates decreasing
   - Validate core functionality
   - Document rollback execution

**Success Criteria:**
- Rollback completed within time limit
- Service restored to stable state
- Comprehensive incident documentation

### Drill 2: Database Schema Rollback

**Scenario:** Schema migration causing data corruption
**Objective:** Roll back database schema changes
**Frequency:** Quarterly

**Steps:**
1. **Preparation**
   - Ensure database backups current
   - Verify rollback scripts tested
   - Prepare maintenance window

2. **Execution**
   - Execute schema rollback procedures
   - Validate data consistency
   - Monitor application functionality

3. **Verification**
   - Run data integrity checks
   - Confirm application compatibility
   - Monitor performance metrics

4. **Documentation**
   - Document rollback reasons
   - Update migration procedures
   - Schedule root cause analysis

### Drill 3: Infrastructure Configuration Rollback

**Scenario:** Configuration change causing system instability
**Objective:** Roll back infrastructure changes
**Frequency:** Monthly

**Steps:**
1. **Detection**
   - Monitor system health metrics
   - Identify configuration-related issues
   - Trace changes to specific deployment

2. **Execution**
   - Revert to previous configuration version
   - Apply known good configuration
   - Verify system stability

3. **Validation**
   - Monitor system performance
   - Validate all services operational
   - Confirm security posture maintained

4. **Analysis**
   - Conduct post-incident review
   - Identify configuration management improvements
   - Update change control procedures

## Combined Drills

### Drill: Simultaneous Secret Rotation and Rollback

**Scenario:** Security incident requiring immediate response
**Objective:** Execute coordinated rotation and rollback under pressure
**Frequency:** Semi-annually

**Steps:**
1. **Incident Declaration**
   - Declare security incident
   - Activate emergency response team
   - Establish communication channels

2. **Coordinated Execution**
   - Simultaneously rotate compromised secrets
   - Execute rollback to known secure state
   - Monitor for collateral damage

3. **Validation**
   - Verify system security restored
   - Confirm operational stability
   - Document all actions taken

4. **Post-Incident**
   - Conduct thorough investigation
   - Implement preventive measures
   - Update emergency procedures

## Drill Execution Guidelines

### Timing and Scheduling
- **Regular Drills:** Schedule during business hours with advance notice
- **Emergency Drills:** Conduct unannounced drills quarterly
- **Duration:** Most drills should complete within 30-60 minutes
- **Frequency:** See individual drill recommendations

### Participant Roles
- **Drill Coordinator:** Oversees execution and timing
- **Technical Team:** Executes rotation/rollback procedures
- **Monitoring Team:** Tracks progress and validates success
- **Documentation Team:** Records all actions and outcomes

### Success Metrics
- **Time to Completion:** Measure against target timelines
- **Error Rate:** Track mistakes and procedural errors
- **Communication Effectiveness:** Assess clarity and timeliness
- **Documentation Quality:** Evaluate completeness and accuracy

### Post-Drill Activities
1. **Immediate Debrief:** Conduct right after drill completion
2. **Lessons Learned:** Identify improvements for procedures
3. **Action Items:** Assign specific improvements with deadlines
4. **Procedure Updates:** Incorporate learnings into official documentation
5. **Follow-up Drills:** Schedule additional practice for identified weak areas

## Template Materials

### Drill Log Template
```markdown
# Drill Log - [Drill Type] - [Date]

## Participants
- [Role]: [Name]
- [Role]: [Name]

## Timeline
- [Time]: [Action] - [Result]
- [Time]: [Action] - [Result]

## Key Metrics
- Time to completion: [Duration]
- Errors encountered: [Count]
- Communication score: [Rating]

## Lessons Learned
- [Observation] - [Improvement Action]
- [Observation] - [Improvement Action]

## Action Items
- [Task] - [Owner] - [Due Date]
- [Task] - [Owner] - [Due Date]
```

### Emergency Checklist
```markdown
# Emergency Secret Rotation Checklist

## Pre-Rotation
- [ ] Identify all affected systems
- [ ] Prepare new secrets in secure storage
- [ ] Notify dependent teams
- [ ] Schedule maintenance window if needed

## During Rotation
- [ ] Deploy new secrets simultaneously
- [ ] Verify functionality after each update
- [ ] Monitor for service disruptions

## Post-Rotation
- [ ] Revoke old secrets immediately
- [ ] Update access records
- [ ] Conduct post-mortem analysis
```

## Continuous Improvement

- **Regular Review:** Update drills based on technology changes
- **Threat Intelligence:** Incorporate new attack vectors into scenarios
- **Tooling Improvements:** Enhance automation for faster execution
- **Cross-Training:** Ensure multiple team members can execute each procedure
- **Metrics Tracking:** Monitor drill performance over time for trends