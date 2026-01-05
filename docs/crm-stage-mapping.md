# CRM Stage Mapping and Gating Rules

This document defines the opportunity lifecycle stages, progression rules, and gating criteria for the CRM-ADLC system.

## Overview

The CRM-ADLC system uses a stage-gated approach to opportunity management, where opportunities must meet specific criteria and complete required artifacts before advancing to the next stage.

## Opportunity Lifecycle Stages

### 1. Pre-Qualification (`pre_qualify`)

**Purpose:** Initial assessment of opportunity viability

**Entry Criteria:**
- New lead or opportunity identified
- Initial contact made with prospect

**Activities:**
- Gather basic information about the opportunity
- Understand customer pain points
- Assess budget and timeline
- Identify decision maker
- Evaluate fit with company offerings

**Required Information:**
- Company name and basic details
- Budget range
- Timeline expectations
- Decision maker identification
- Pain points documentation
- Initial interest level assessment

**Exit Criteria:**
- All pre-qualification fields completed
- Initial interest level assessed as "Medium" or higher
- Budget range aligns with solution pricing
- Decision to pursue opportunity confirmed

**Required Artifacts:**
- None (artifacts begin in next stage)

**Typical Duration:** 1-2 weeks

---

### 2. MEDPICC Qualification (`medpicc_qualification`)

**Purpose:** Deep qualification using MEDPICC methodology

**Entry Criteria:**
- Successfully completed pre-qualification
- Intent Brief artifact created and approved
- Stakeholder access confirmed

**Activities:**
- Complete full MEDPICC assessment:
  - **M**etrics: Define success metrics customer will use to evaluate solution
  - **E**conomic Buyer: Identify who has budget authority
  - **D**ecision Criteria: Understand technical and business criteria for selection
  - **D**ecision Process: Map out the buying/approval process
  - **I**dentify Pain: Quantify the business impact of current problems
  - **C**hampion: Find and develop internal advocate

**Required Information:**
- All six MEDPICC components documented
- MEDPICC score ≥ 70 (at least 5 of 6 components completed)

**Required Artifacts:**
1. **Intent Brief** (Status: Approved)
   - Documents initial customer interest and project scope
   - Must be reviewed and approved by reviewer role

**Exit Criteria:**
- MEDPICC score ≥ 70
- Intent Brief approved
- Champion identified and engaged
- Economic buyer confirmed
- Decision process mapped
- MVP Specification ready for review

**Gating Logic:**
```
CAN_ADVANCE = (
    medpicc_score >= 70 AND
    artifact_exists("intent_brief", status="approved") AND
    economic_buyer IS NOT NULL AND
    champion IS NOT NULL
)
```

**Typical Duration:** 2-4 weeks

---

### 3. Solutioning (`solutioning`)

**Purpose:** Develop and validate technical solution

**Entry Criteria:**
- MEDPICC qualification completed
- MEDPICC score ≥ 70
- Intent Brief and MVP Spec approved
- Technical resources allocated

**Activities:**
- Design solution architecture
- Create detailed MVP specification
- Define user experience flows
- Develop build plan with timeline and resources
- Create comprehensive test plan
- Prepare customer demonstration
- Plan deployment approach

**Required Artifacts:**
1. **Intent Brief** (Status: Approved) - carried forward
2. **MVP Specification** (Status: Approved)
   - Defines minimum viable product features
   - Includes user stories and acceptance criteria
3. **Architecture Summary** (Status: Approved)
   - Documents technical architecture
   - Technology stack decisions
   - Integration points
4. **UX Flow** (Status: Submitted or Approved)
   - User journey maps
   - Wireframes for key screens
5. **Build Plan** (Status: Submitted or Approved)
   - Development timeline
   - Resource allocation
   - Milestones
6. **Test Plan** (Status: Submitted or Approved)
   - Testing strategy
   - Test scenarios
   - Acceptance criteria
7. **Demo Script** (Optional but recommended)
   - Customer presentation guide
8. **Deployment Checklist** (Draft)
   - Production readiness checklist

**Exit Criteria:**
- All required artifacts approved
- Solution validated by technical review
- Customer demo completed successfully
- Pricing and proposal approved
- Contract terms negotiated

**Gating Logic:**
```
CAN_ADVANCE = (
    artifact_exists("intent_brief", status="approved") AND
    artifact_exists("mvp_spec", status="approved") AND
    artifact_exists("architecture", status="approved") AND
    (artifact_exists("build_plan", status="approved") OR 
     artifact_exists("build_plan", status="submitted")) AND
    (artifact_exists("test_plan", status="approved") OR
     artifact_exists("test_plan", status="submitted"))
)
```

**Typical Duration:** 4-8 weeks

---

### 4. Closed Won (`closed_won`)

**Purpose:** Opportunity successfully closed, contract signed

**Entry Criteria:**
- All solutioning artifacts approved
- Contract signed
- Purchase order received
- Implementation team identified

**Activities:**
- Project kickoff
- Begin implementation
- Ongoing project management
- Customer success handoff

**Required Artifacts:**
- All artifacts from Solutioning stage
- **Deployment Checklist** (Status: Approved)
- Signed contract (stored externally)

**Exit:** Opportunity complete, moves to project management/delivery

---

### 5. Closed Lost (`closed_lost`)

**Purpose:** Opportunity not won, document lessons learned

**Entry Criteria:**
- Customer declined proposal, OR
- Opportunity no longer viable, OR
- Customer selected competitor

**Activities:**
- Document loss reason
- Capture lessons learned
- Update CRM records
- Archive opportunity

**Required Artifacts:**
- Loss analysis (informal documentation)

**Exit:** Opportunity archived

---

## Stage Progression Flow

```
┌─────────────────┐
│  Pre-Qualify    │
│                 │
│  - Basic info   │
│  - Pain points  │
│  - Budget range │
└────────┬────────┘
         │ [Decision to pursue]
         ↓
┌─────────────────┐
│    MEDPICC      │
│  Qualification  │
│                 │
│ Required:       │
│ • Intent Brief  │
│ • MEDPICC ≥70   │
└────────┬────────┘
         │ [Qualification passed]
         ↓
┌─────────────────┐
│   Solutioning   │
│                 │
│ Required:       │
│ • MVP Spec      │
│ • Architecture  │
│ • Build Plan    │
│ • Test Plan     │
└────────┬────────┘
         │ [Solution approved]
         ↓
┌─────────────────┐
│  Closed Won     │
│                 │
│ • Contract      │
│ • Deployment    │
└─────────────────┘

(From any stage)
         ↓
┌─────────────────┐
│  Closed Lost    │
└─────────────────┘
```

## Gating Rules Implementation

### Rule 1: Pre-Qualify → MEDPICC Qualification

**Prerequisites:**
- All pre-qualification fields completed
- Budget range acceptable
- Initial interest level ≥ "Medium"

**Validation:**
```python
def can_advance_to_medpicc(opportunity):
    return (
        opportunity.budget_range is not None and
        opportunity.timeline is not None and
        opportunity.decision_maker is not None and
        opportunity.pain_points is not None and
        opportunity.initial_interest_level in ['Medium', 'High', 'Very High']
    )
```

**Actions on Advancement:**
- Create Intent Brief artifact (draft)
- Notify BDM to begin MEDPICC assessment
- Update opportunity owner if needed

---

### Rule 2: MEDPICC Qualification → Solutioning

**Prerequisites:**
- MEDPICC score ≥ 70 (at least 5 of 6 components)
- Intent Brief artifact approved
- Economic buyer identified
- Champion identified

**Validation:**
```python
def can_advance_to_solutioning(opportunity, artifacts):
    intent_brief_approved = any(
        a.type == 'intent_brief' and a.status == 'approved'
        for a in artifacts
    )
    
    return (
        opportunity.medpicc_score >= 70 and
        intent_brief_approved and
        opportunity.economic_buyer is not None and
        opportunity.champion is not None
    )
```

**Actions on Advancement:**
- Assign technical resources
- Create MVP Spec artifact (draft)
- Create Architecture artifact (draft)
- Schedule technical kickoff meeting
- Snapshot MEDPICC scores to history table

---

### Rule 3: Solutioning → Closed Won

**Prerequisites:**
- All required artifacts approved:
  - Intent Brief
  - MVP Specification
  - Architecture Summary
  - Build Plan
  - Test Plan
- Demo completed
- Proposal submitted and accepted
- Contract signed

**Validation:**
```python
def can_advance_to_closed_won(opportunity, artifacts):
    required_artifacts = ['intent_brief', 'mvp_spec', 'architecture']
    
    approved_artifacts = [
        a.type for a in artifacts 
        if a.status == 'approved'
    ]
    
    # Check all required artifacts are approved
    all_approved = all(
        req in approved_artifacts 
        for req in required_artifacts
    )
    
    # At least build_plan or test_plan should be submitted/approved
    has_build_or_test = any(
        a.type in ['build_plan', 'test_plan'] and 
        a.status in ['submitted', 'approved']
        for a in artifacts
    )
    
    return all_approved and has_build_or_test
```

**Actions on Advancement:**
- Snapshot final MEDPICC scores
- Notify delivery team
- Create project in project management system
- Update revenue forecasting
- Schedule kickoff meeting

---

### Rule 4: Any Stage → Closed Lost

**Prerequisites:**
- Loss reason documented

**Validation:**
```python
def can_mark_closed_lost(opportunity, loss_reason):
    return loss_reason is not None and len(loss_reason) > 0
```

**Actions on Closure:**
- Record loss reason
- Capture competitor information (if applicable)
- Document lessons learned
- Update forecasting
- Archive opportunity

---

## Artifact Review Workflow

### Review Roles
- **BDM (Business Development Manager)**: Creates and owns artifacts
- **Reviewer**: Reviews and approves/rejects artifacts
- **Admin**: Can override any status

### Review Process

1. **Artifact Created** (Status: Draft)
   - BDM creates artifact using template
   - Artifact visible to all team members

2. **Submitted for Review** (Status: Submitted)
   - BDM submits completed artifact
   - Notification sent to reviewers
   - Artifact locked for editing

3. **Under Review**
   - Reviewer evaluates artifact
   - Reviewer can:
     - Approve → Status: Approved
     - Reject → Status: Rejected (with comments)
     - Request revision → Status: Needs Revision

4. **Needs Revision** 
   - BDM makes changes
   - Resubmits for review
   - Returns to "Submitted" status

5. **Approved**
   - Artifact approved
   - Counts toward stage gate requirements
   - Can still be edited if reopened by admin

6. **Rejected**
   - Artifact not acceptable
   - BDM must address issues
   - Can resubmit as new version

### Review SLAs
- Intent Brief: 2 business days
- MVP Spec: 3 business days
- Architecture: 3 business days
- Other artifacts: 1-2 business days

---

## MEDPICC Scoring

### Scoring Algorithm

Each MEDPICC component is worth approximately 16-17 points:

```
Score Calculation:
- Metrics: 17 points (if filled)
- Economic Buyer: 17 points (if filled)
- Decision Criteria: 17 points (if filled)
- Decision Process: 17 points (if filled)
- Identify Pain: 16 points (if filled)
- Champion: 16 points (if filled)

Total Possible: 100 points
```

### Score Interpretation

- **0-30**: Poor qualification - High risk, needs immediate attention
- **31-50**: Weak qualification - Multiple gaps, unlikely to close
- **51-70**: Moderate qualification - Some gaps, proceed with caution
- **71-85**: Good qualification - Ready for solutioning
- **86-100**: Excellent qualification - All components documented

### Score Thresholds

- **Minimum to advance**: 70 (at least 5 of 6 components)
- **Recommended for solutioning**: 85+
- **Red flag**: Score decreasing over time

### Scoring Triggers

- **Auto-compute**: Score automatically updated when MEDPICC fields change
- **Snapshot**: Score saved to history when stage changes
- **Alerts**: Notifications if score drops below 70 in MEDPICC/Solutioning stages

---

## Priority Scoring

Opportunities are prioritized using a composite score:

```
Priority Score = (Value × Probability × (1 + MEDPICC_Score/100)) / 100

Where:
- Value: Opportunity value in dollars
- Probability: Win probability (0-100)
- MEDPICC_Score: MEDPICC qualification score (0-100)
```

### Priority Levels

- **Critical**: Priority Score ≥ 100,000
- **High**: Priority Score ≥ 50,000
- **Medium**: Priority Score ≥ 20,000
- **Low**: Priority Score < 20,000

### Example Calculations

| Value | Probability | MEDPICC | Formula | Score | Level |
|-------|-------------|---------|---------|-------|-------|
| $500K | 80% | 100 | (500k × 80 × 2.0) / 100 | 800,000 | Critical |
| $250K | 65% | 67 | (250k × 65 × 1.67) / 100 | 271,537 | Critical |
| $85K | 30% | 0 | (85k × 30 × 1.0) / 100 | 25,500 | Medium |

---

## Role-Based Access

### Admin
- Full access to all data
- Can override stage gates
- Can delete opportunities
- Can manage users and tenants

### BDM (Business Development Manager)
- Create and edit opportunities
- Create and submit artifacts
- Advance opportunities through stages (subject to gates)
- View all opportunities in tenant

### Reviewer
- Review and approve/reject artifacts
- Provide feedback on submissions
- View all opportunities
- Cannot create or edit opportunities

### Student
- Read-only access
- View opportunities and artifacts
- Cannot create, edit, or approve

---

## Notifications and Alerts

### Stage Change Notifications
- Opportunity owner
- Assigned reviewers
- Sales management

### Artifact Review Notifications
- When submitted: Notify reviewers
- When approved/rejected: Notify creator
- Overdue reviews: Daily reminder to reviewers

### Score Alerts
- MEDPICC score drops below 70: Notify owner and manager
- Opportunity stuck in stage >30 days: Notify owner
- High-value opportunity ($500K+) created: Notify sales leadership

---

## Reporting and Analytics

### Key Metrics

1. **Stage Velocity**
   - Average time in each stage
   - Bottlenecks identification

2. **MEDPICC Health**
   - Average MEDPICC score by stage
   - Score trends over time

3. **Artifact Completion Rate**
   - % of opportunities with required artifacts
   - Average review time by artifact type

4. **Win Rate by Stage**
   - Conversion rate at each gate
   - Win rate correlated with MEDPICC score

5. **Pipeline Value**
   - Total value by stage
   - Weighted pipeline (value × probability)

---

## Best Practices

### For BDMs
1. Complete pre-qualification thoroughly before advancing
2. Engage champion early in MEDPICC stage
3. Use artifact templates consistently
4. Keep MEDPICC information current
5. Request reviews promptly to avoid delays

### For Reviewers
1. Provide constructive, specific feedback
2. Meet SLA targets for review completion
3. Use "Needs Revision" for minor issues
4. Reject only for major gaps or misalignment
5. Document review rationale in comments

### For Admins
1. Monitor stage progression regularly
2. Intervene on stalled opportunities
3. Enforce gating rules consistently
4. Review MEDPICC score trends
5. Ensure artifact quality standards maintained

---

*Last Updated: January 2026*
