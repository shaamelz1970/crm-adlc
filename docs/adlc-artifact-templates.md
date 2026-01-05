# ADLC Artifact Templates

This document defines the standard artifact templates for the Artifact-Driven Lifecycle (ADLC) methodology in the CRM-ADLC system. Each artifact corresponds to a specific stage of the opportunity lifecycle and has specific requirements and structure.

## Overview

ADLC artifacts are deliverables that gate progression through opportunity stages. Each artifact must be reviewed and approved before an opportunity can advance to the next stage.

## Artifact Types

### 1. Intent Brief

**Stage:** Pre-qualification → MEDPICC Qualification  
**Purpose:** Document initial customer interest and project scope  
**Required for:** Advancing to MEDPICC Qualification

**Template Structure:**

```markdown
# Intent Brief: [Customer Name] - [Project Name]

## Executive Summary
- One paragraph overview of the opportunity
- Key business drivers
- Expected outcomes

## Customer Background
- Company overview
- Industry and market position
- Current situation/challenges

## Stated Requirements
- Primary needs expressed by customer
- Technical requirements (if known)
- Business requirements
- Timeline expectations

## Initial Scope
- Proposed solution area
- High-level deliverables
- Exclusions/out of scope

## Business Case
- Budget range: $X - $Y
- Expected benefits/ROI
- Timeline: Start date, completion date

## Next Steps
- Actions required to move forward
- Key decisions needed
- Stakeholders to engage

## Risks and Concerns
- Known risks
- Open questions
- Dependencies
```

---

### 2. MVP Specification

**Stage:** MEDPICC Qualification → Solutioning  
**Purpose:** Define minimum viable product features and acceptance criteria  
**Required for:** Advancing to Solutioning

**Template Structure:**

```markdown
# MVP Specification: [Project Name]

## Product Vision
- Problem statement
- Target users
- Value proposition

## MVP Scope
### In Scope
- Feature 1: [Description]
  - User story
  - Acceptance criteria
- Feature 2: [Description]
  - User story
  - Acceptance criteria
- Feature N...

### Out of Scope (Future Phases)
- Deferred features
- Future enhancements

## User Personas
- Primary persona: [Name/Role]
  - Goals
  - Pain points
  - Success criteria
- Secondary personas...

## Functional Requirements
| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | [Description] | Must Have | [Criteria] |
| FR-2 | [Description] | Should Have | [Criteria] |

## Non-Functional Requirements
- Performance targets
- Security requirements
- Scalability requirements
- Compliance needs

## Success Metrics
- Key Performance Indicators (KPIs)
- Measurement approach
- Target values

## Assumptions and Dependencies
- Technical assumptions
- Business assumptions
- External dependencies

## Release Criteria
- Definition of "done"
- Launch checklist
```

---

### 3. Architecture Summary

**Stage:** Solutioning  
**Purpose:** Document technical architecture and design decisions  
**Required for:** Solution approval

**Template Structure:**

```markdown
# Architecture Summary: [Project Name]

## Overview
- Solution overview
- Architectural goals
- Key design principles

## System Context
- System boundaries
- External systems and integrations
- User groups

## Architecture Diagram
[Include high-level architecture diagram]

## Component Architecture
### Component 1: [Name]
- Responsibility
- Technology stack
- Key interfaces

### Component 2: [Name]
...

## Data Architecture
- Data models
- Data flow
- Storage strategy
- Backup and recovery

## Integration Points
| System | Integration Type | Protocol | Purpose |
|--------|-----------------|----------|---------|
| [Name] | API/Event/Batch | REST/SOAP/etc | [Purpose] |

## Technology Stack
- Frontend: [Technologies]
- Backend: [Technologies]
- Database: [Technologies]
- Infrastructure: [Cloud provider, services]
- DevOps: [CI/CD, monitoring]

## Security Architecture
- Authentication/Authorization approach
- Data encryption (at rest, in transit)
- Security controls
- Compliance considerations

## Scalability and Performance
- Expected load
- Scaling strategy
- Performance optimization approach

## Deployment Architecture
- Environment strategy (dev, staging, prod)
- Deployment model
- Rollback strategy

## Risks and Mitigations
| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| [Risk] | High/Med/Low | High/Med/Low | [Strategy] |

## Decision Log
- Key architectural decisions
- Alternatives considered
- Rationale
```

---

### 4. UX Flow

**Stage:** Solutioning  
**Purpose:** Document user experience and interaction flows  
**Required for:** Design approval

**Template Structure:**

```markdown
# UX Flow: [Project Name]

## User Journey Maps
### Journey 1: [Primary User Flow]
- Entry point
- User goals
- Steps
- Exit criteria

## Screen/Page Flows
[Include wireframes or mockups]

### Flow 1: [e.g., User Registration]
1. Landing page
2. Registration form
3. Email verification
4. Welcome/Onboarding

## Wireframes
[Include low-fidelity wireframes for key screens]

### Screen 1: [Name]
- Purpose
- Key elements
- User actions

## Interaction Patterns
- Navigation model
- Common UI patterns
- Form validations
- Error handling

## Responsive Design Considerations
- Mobile breakpoints
- Tablet considerations
- Desktop optimizations

## Accessibility Requirements
- WCAG compliance level
- Screen reader support
- Keyboard navigation
- Color contrast

## Design System References
- Color palette
- Typography
- Component library
- Style guide

## User Feedback Mechanisms
- Error messages
- Success confirmations
- Loading states
- Help/tooltips
```

---

### 5. Build Plan

**Stage:** Solutioning  
**Purpose:** Define development approach, timeline, and resource allocation  
**Required for:** Development kickoff

**Template Structure:**

```markdown
# Build Plan: [Project Name]

## Project Overview
- Objectives
- Scope summary
- Key deliverables

## Team Structure
| Role | Name | Allocation | Responsibilities |
|------|------|------------|------------------|
| Project Manager | [Name] | 100% | [Responsibilities] |
| Tech Lead | [Name] | 100% | [Responsibilities] |
| Developer | [Name] | 100% | [Responsibilities] |

## Development Phases
### Phase 1: [Name] (Weeks 1-2)
- Goals
- Deliverables
- Tasks
  - Task 1: [Description] - [Owner] - [Duration]
  - Task 2...

### Phase 2: [Name] (Weeks 3-4)
...

## Technical Approach
- Development methodology (Agile, Scrum, etc.)
- Sprint length
- Release cadence
- Branching strategy

## Development Environment Setup
- Required tools and software
- Local development setup
- Shared environments (dev, staging)

## Dependencies and Prerequisites
- External dependencies
- Required access/permissions
- Third-party services

## Quality Assurance Approach
- Code review process
- Testing strategy
- Definition of Done

## Risk Management
| Risk | Impact | Mitigation |
|------|--------|------------|
| [Risk] | High/Med/Low | [Strategy] |

## Timeline and Milestones
| Milestone | Target Date | Deliverables |
|-----------|-------------|--------------|
| Kickoff | [Date] | Team onboarded, env setup |
| MVP Alpha | [Date] | Core features complete |
| Beta Release | [Date] | All features, internal testing |
| Launch | [Date] | Production deployment |

## Communication Plan
- Daily standups
- Weekly status reports
- Stakeholder reviews
- Demo schedule
```

---

### 6. Test Plan

**Stage:** Solutioning  
**Purpose:** Define testing strategy and acceptance criteria  
**Required for:** Quality gate

**Template Structure:**

```markdown
# Test Plan: [Project Name]

## Test Strategy Overview
- Testing objectives
- Scope of testing
- Out of scope

## Test Levels
### Unit Testing
- Approach
- Coverage target: X%
- Tools: [Jest, pytest, etc.]

### Integration Testing
- Approach
- Key integration points
- Tools

### System Testing
- End-to-end scenarios
- Tools

### User Acceptance Testing (UAT)
- UAT approach
- User groups
- Success criteria

## Test Scenarios
### Scenario 1: [Name]
- Preconditions
- Test steps
- Expected results
- Pass/Fail criteria

### Scenario 2: [Name]
...

## Performance Testing
- Load testing approach
- Performance targets
- Tools

## Security Testing
- Security test cases
- Penetration testing plan
- Vulnerability scanning

## Test Environment
- Environment setup
- Test data requirements
- Access requirements

## Test Schedule
| Test Phase | Start Date | End Date | Owner |
|------------|------------|----------|-------|
| Unit Testing | [Date] | [Date] | Dev Team |
| Integration Testing | [Date] | [Date] | QA Team |
| UAT | [Date] | [Date] | Business Users |

## Defect Management
- Defect tracking tool
- Severity definitions
- Resolution process

## Test Deliverables
- Test cases document
- Test execution report
- Defect report
- Test coverage report

## Entry and Exit Criteria
### Entry Criteria
- Code complete
- Test environment ready
- Test data prepared

### Exit Criteria
- All critical/high bugs resolved
- Test coverage target met
- UAT sign-off obtained

## Risks and Contingencies
- Testing risks
- Mitigation strategies
```

---

### 7. Demo Script

**Stage:** Solutioning → Closed Won  
**Purpose:** Guide for demonstrating solution to stakeholders  
**Required for:** Customer presentation

**Template Structure:**

```markdown
# Demo Script: [Project Name]

## Demo Overview
- Audience: [Stakeholders]
- Duration: [X minutes]
- Objectives
- Key messages

## Pre-Demo Checklist
- [ ] Demo environment verified
- [ ] Test data loaded
- [ ] Backup demo ready
- [ ] Screen sharing tested
- [ ] Participants invited

## Demo Flow

### Introduction (2 minutes)
**Say:** "Welcome everyone. Today we'll demonstrate [solution]..."

**Do:** 
- Open application
- Show login screen

### Section 1: [Feature/Module Name] (5 minutes)
**Say:** "Let me show you how [feature] solves [problem]..."

**Do:**
1. Navigate to [screen]
2. Demonstrate [action]
3. Highlight [key benefit]

**Key Points:**
- Benefit 1
- Benefit 2

### Section 2: [Feature/Module Name] (5 minutes)
...

### Q&A and Wrap-up (3 minutes)
**Anticipated Questions:**
- Q: [Question]
  - A: [Answer]

**Closing:**
- Summary of key benefits
- Next steps
- Thank you

## Demo Notes
- Talking points
- Areas to emphasize
- Things to avoid

## Technical Setup
- Demo environment URL
- Test credentials
- Sample data scenarios

## Backup Plans
- If demo environment is down: [Alternative]
- If feature fails: [Workaround]
- If time runs short: [Priority order]
```

---

### 8. Deployment Checklist

**Stage:** Solutioning → Closed Won  
**Purpose:** Ensure readiness for production deployment  
**Required for:** Production release

**Template Structure:**

```markdown
# Deployment Checklist: [Project Name]

## Pre-Deployment

### Code Readiness
- [ ] All code merged to main/production branch
- [ ] Code review completed
- [ ] All tests passing (unit, integration, E2E)
- [ ] No critical or high-priority bugs open
- [ ] Version tagged: vX.Y.Z

### Environment Readiness
- [ ] Production environment provisioned
- [ ] Database migrations prepared and tested
- [ ] Configuration files updated
- [ ] Environment variables set
- [ ] SSL certificates installed and valid

### Security
- [ ] Security scan completed
- [ ] Penetration testing completed (if applicable)
- [ ] Secrets rotated
- [ ] Access controls configured
- [ ] GDPR/compliance requirements verified

### Documentation
- [ ] User documentation updated
- [ ] API documentation published
- [ ] Runbook created
- [ ] Rollback procedure documented

### Stakeholder Communication
- [ ] Deployment notification sent
- [ ] Maintenance window scheduled
- [ ] Support team briefed
- [ ] Customers notified (if applicable)

## Deployment Steps

### Step 1: Backup
- [ ] Database backup completed
- [ ] Configuration backup completed
- [ ] Previous version tagged

### Step 2: Database Migration
- [ ] Migration scripts reviewed
- [ ] Dry-run completed in staging
- [ ] Execute migrations in production
- [ ] Verify migration success

### Step 3: Application Deployment
- [ ] Deploy application code
- [ ] Restart services
- [ ] Verify services started successfully

### Step 4: Verification
- [ ] Smoke tests passed
- [ ] Health check endpoints responding
- [ ] Key user flows tested
- [ ] Monitoring dashboards verified

### Step 5: Performance Check
- [ ] Response times acceptable
- [ ] Error rates normal
- [ ] Resource utilization normal

## Post-Deployment

### Monitoring (First 24 hours)
- [ ] Monitor error logs
- [ ] Watch performance metrics
- [ ] Check user feedback
- [ ] Monitor support tickets

### Documentation
- [ ] Deployment notes documented
- [ ] Lessons learned captured
- [ ] Known issues documented

### Communication
- [ ] Success notification sent
- [ ] Release notes published
- [ ] Status page updated

## Rollback Procedure (If Needed)

### Triggers for Rollback
- Critical bug affecting core functionality
- Performance degradation >X%
- Data integrity issues

### Rollback Steps
1. [ ] Stop new deployments
2. [ ] Revert to previous version
3. [ ] Restore database (if needed)
4. [ ] Verify rollback success
5. [ ] Communicate to stakeholders

## Sign-off

- [ ] Technical Lead approval
- [ ] Product Owner approval
- [ ] Operations team approval
- [ ] Security team approval (if applicable)

**Deployment Date:** [Date]  
**Deployed By:** [Name]  
**Approved By:** [Name]  
**Status:** Success / Rollback Required
```

---

## Using These Templates

1. **Copy the relevant template** when creating a new artifact
2. **Fill in all sections** with specific project information
3. **Submit for review** according to the approval workflow
4. **Update as needed** based on reviewer feedback
5. **Mark as approved** once all requirements are met

## Artifact Workflow

```
Draft → Submitted → Under Review → Approved/Rejected
                                    ↓
                              (if rejected)
                                    ↓
                            Needs Revision → [back to Draft]
```

## Review SLA

- **Intent Brief:** 2 business days
- **MVP Spec:** 3 business days
- **Architecture Summary:** 3 business days
- **UX Flow:** 2 business days
- **Build Plan:** 2 business days
- **Test Plan:** 2 business days
- **Demo Script:** 1 business day
- **Deployment Checklist:** 1 business day

---

*Last Updated: January 2026*
