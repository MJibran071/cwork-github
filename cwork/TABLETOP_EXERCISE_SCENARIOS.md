# Tabletop Exercise Scenarios

## Overview
This document provides structured tabletop exercise scenarios for practicing incident response procedures. These exercises are designed to test and improve the team's ability to handle security incidents effectively.

## Exercise Structure

### Pre-Exercise Preparation
- **Participants:** Incident response team, relevant stakeholders
- **Duration:** 2-3 hours per scenario
- **Materials:** Incident response plan, communication templates, role cards
- **Facilitator:** Security lead or external consultant

### Post-Exercise Activities
- Debrief and lessons learned
- Action items for plan improvements
- Documentation of findings

## Scenario 1: Credential Stuffing Attack

### Scenario Description
**Time:** Monday morning, 9:00 AM
**Trigger:** Multiple failed login attempts detected across user accounts
**Background:** Attackers are using compromised credentials from third-party breaches to attempt access to CWork accounts.

### Injection Points
- **10:00 AM:** Alert from monitoring system: 50 failed login attempts in last 5 minutes
- **10:15 AM:** User reports account lockout via support ticket
- **10:30 AM:** Additional alerts: suspicious IP addresses from multiple geographic locations
- **11:00 AM:** Evidence of successful login from unrecognized device

### Exercise Goals
1. Practice initial detection and triage
2. Execute containment procedures
3. Communicate effectively with stakeholders
4. Document incident response steps

### Roles and Responsibilities
- **Incident Commander:** Coordinate response
- **Technical Lead:** Investigate logs, implement blocks
- **Communications Lead:** Prepare customer notifications
- **Support Lead:** Handle user inquiries

### Discussion Questions
1. How do you initially assess the severity?
2. What immediate containment actions are taken?
3. How do you communicate with affected users?
4. What forensic evidence should be preserved?
5. How do you prevent future similar attacks?

## Scenario 2: Ransomware Infection

### Scenario Description
**Time:** Friday afternoon, 4:00 PM
**Trigger:** Systems team notices encrypted files on development server
**Background:** Developer clicked on malicious email attachment, leading to ransomware deployment.

### Injection Points
- **4:00 PM:** Developer reports encrypted files on local machine
- **4:15 PM:** Network monitoring detects unusual outbound traffic
- **4:30 PM:** Ransom note appears on affected systems
- **5:00 PM:** Additional systems show signs of infection

### Exercise Goals
1. Practice isolation and containment
2. Execute recovery procedures
3. Manage external communications
4. Coordinate with legal and law enforcement

### Roles and Responsibilities
- **Incident Commander:** Lead response efforts
- **Technical Lead:** Isolate systems, assess damage
- **Legal Counsel:** Advise on ransomware payment considerations
- **Communications Lead:** Handle media inquiries

### Discussion Questions
1. How do you contain the spread of ransomware?
2. What recovery options are available?
3. How do you communicate with stakeholders?
4. What legal obligations exist?
5. How do you prevent recurrence?

## Scenario 3: Data Breach Incident

### Scenario Description
**Time:** Wednesday, 2:00 PM
**Trigger:** Security researcher reports exposed database online
**Background:** Misconfigured cloud storage bucket exposed user data to public internet.

### Injection Points
- **2:00 PM:** External report of exposed database
- **2:15 PM:** Internal verification confirms exposure
- **2:30 PM:** Assessment of data sensitivity and scope
- **3:00 PM:** Evidence of data access by unknown parties

### Exercise Goals
1. Practice breach assessment and scope determination
2. Execute notification procedures
3. Manage regulatory compliance requirements
4. Coordinate with external parties

### Roles and Responsibilities
- **Incident Commander:** Oversee breach response
- **Technical Lead:** Secure exposed resources
- **Legal Counsel:** Guide regulatory compliance
- **Communications Lead:** Manage customer notifications

### Discussion Questions
1. How do you determine the scope of the breach?
2. What notification timelines apply?
3. How do you engage with regulatory bodies?
4. What remediation steps are required?
5. How do you prevent similar misconfigurations?

## Scenario 4: DDoS Attack

### Scenario Description
**Time:** Tuesday, 11:00 AM
**Trigger:** Website becomes unresponsive, monitoring alerts trigger
**Background:** Competitor launches distributed denial-of-service attack against CWork infrastructure.

### Injection Points
- **11:00 AM:** Website performance degradation noticed
- **11:15 AM:** Monitoring alerts indicate traffic spike
- **11:30 AM:** Core services become unavailable
- **12:00 PM:** Customer complaints escalate

### Exercise Goals
1. Practice DDoS mitigation procedures
2. Execute service restoration
3. Manage customer communications
4. Coordinate with infrastructure providers

### Roles and Responsibilities
- **Incident Commander:** Direct mitigation efforts
- **Technical Lead:** Implement DDoS protections
- **Operations Lead:** Coordinate with cloud providers
- **Support Lead:** Handle customer communications

### Discussion Questions
1. How do you initially respond to service degradation?
2. What mitigation strategies are employed?
3. How do you communicate service status?
4. What post-incident analysis is required?
5. How do you strengthen defenses against future attacks?

## Exercise Execution Guidelines

### Facilitator Instructions
1. Set the scene and distribute role cards
2. Present injection points at timed intervals
3. Encourage participant discussion and decision-making
4. Document key decisions and actions
5. Guide debrief and lessons learned

### Participant Guidelines
1. Stay in character based on assigned roles
2. Make decisions based on available information
3. Document actions taken during the exercise
4. Participate actively in discussion and debrief

### Evaluation Criteria
- Speed and accuracy of initial response
- Effectiveness of communication
- Completeness of documentation
- Quality of decision-making
- Adherence to incident response plan

## Template Materials

### Role Cards
```markdown
# Incident Commander
**Responsibilities:** Overall decision-making, resource allocation, escalation
**Key Actions:** Activate response team, approve major decisions, communicate with executives

# Technical Lead
**Responsibilities:** Technical investigation, implementation of fixes
**Key Actions:** Analyze logs, implement containment, coordinate technical recovery

# Communications Lead
**Responsibilities:** Internal and external communications
**Key Actions:** Prepare statements, coordinate notifications, manage media inquiries
```

### Incident Log Template
```markdown
# Incident Log - [Scenario Name]

## Timeline
- [Time]: [Event] - [Action Taken]
- [Time]: [Event] - [Action Taken]

## Key Decisions
- [Decision] - [Rationale]
- [Decision] - [Rationale]

## Communications
- [Audience]: [Message] - [Time]
- [Audience]: [Message] - [Time]

## Lessons Learned
- [Observation] - [Improvement]
- [Observation] - [Improvement]
```

## Scheduling and Frequency
- **Quarterly:** Conduct at least one tabletop exercise
- **Annual:** Include all major incident types
- **Post-Release:** Exercise after significant system changes
- **Ad-hoc:** Additional exercises based on emerging threats

## Continuous Improvement
- Update scenarios based on real incidents
- Incorporate new threat intelligence
- Refine procedures based on exercise outcomes
- Share learnings across the organization