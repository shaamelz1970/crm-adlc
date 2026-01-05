# CRM Stage Mapping and Gating Rules

This document defines the opportunity lifecycle stages, required artifacts for each stage, and the gating rules that control stage progression in the CRM-ADLC system.

## Overview

The CRM-ADLC system uses a stage-gated approach to opportunity management, where opportunities must meet specific criteria before advancing to the next stage. This ensures quality control and reduces risk by requiring proper qualification and planning at each phase.

## Opportunity Lifecycle Stages

```
Pre-Qualification → MEDPICC Qualification → Solutioning → Proposal → Negotiation → Closed Won/Lost
```

---

## Stage 1: Pre-Qualification

### Purpose
Initial qualification to determine if the opportunity is worth pursuing. This stage validates that there is a real business need and sufficient information to proceed with deeper qualification.

### Stage Objectives
- Understand the customer's business problem
- Identify key stakeholders
- Assess initial fit with our capabilities
- Document opportunity intent

### Required Artifacts

| Artifact | Type | Description | Approval Required |
|----------|------|-------------|-------------------|
| **Intent Brief** | `intent_brief` | Documents business context, objectives, stakeholders, and constraints | ✅ Yes |

### Artifact Details

#### Intent Brief Requirements
- **Business Context**: Clear description of customer situation
- **Stakeholders**: At least 2 stakeholders identified (including roles and influence level)
- **Objectives**: Minimum of 2 measurable business objectives
- **Success Criteria**: At least 3 quantifiable success metrics
- **Budget/Timeline**: Preliminary constraints documented

### Minimum Criteria
- [ ] Intent Brief artifact created
- [ ] Intent Brief approved by reviewer
- [ ] At least one stakeholder contact identified
- [ ] Business value proposition documented

### Gating Rule to Advance

**To advance from Pre-Qualification to MEDPICC Qualification:**

```python
can_advance = (
    intent_brief.status == 'approved' AND
    stakeholders.count >= 2
)
```

**Business Logic:**
- Intent Brief must be in 'approved' status
- At least 2 stakeholders must be documented

**Blocking Reasons:**
- Intent Brief not created
- Intent Brief in 'draft' or 'review' status
- Intent Brief rejected
- Insufficient stakeholder information

---

## Stage 2: MEDPICC Qualification

### Purpose
Comprehensive opportunity qualification using the MEDPICC framework to ensure we have a strong foundation for solutioning and a high probability of winning.

### Stage Objectives
- Complete MEDPICC assessment
- Identify economic buyer and champion
- Understand decision criteria and process
- Quantify business metrics and pain
- Assess competitive landscape

### Required Artifacts

No additional artifacts are required at this stage, but the opportunity's MEDPICC fields must be completed to a sufficient level.

### MEDPICC Components

The system tracks 7 MEDPICC components, each scored 0-100:

| Component | Field | Scoring Criteria |
|-----------|-------|------------------|
| **Metrics** | `metrics_score`, `value` | Business value quantified with ROI/metrics |
| **Economic Buyer** | `economic_buyer_id` | Decision-maker with budget authority identified |
| **Decision Criteria** | `decision_criteria` | Evaluation criteria documented (>20 chars) |
| **Decision Process** | `decision_process` | Procurement process mapped (>20 chars) |
| **Identify Pain** | `identify_pain` | Business pain clearly articulated (>20 chars) |
| **Champion** | `champion_id` | Internal advocate identified and engaged |
| **Competition** | `competition` | Competitive landscape documented (>20 chars) |

### MEDPICC Scoring

**Component Scoring Logic:**
- **Metrics**: 
  - 0 if no value defined
  - 50 if value defined but metrics_score not set
  - metrics_score value if set
  
- **Economic Buyer**:
  - 0 if not identified
  - 50 if identified but not confirmed as economic buyer
  - 100 if confirmed as economic buyer (contact.is_economic_buyer = true)

- **Decision Criteria**:
  - 0 if empty
  - 50 if partially documented (1-20 chars)
  - 100 if fully documented (>20 chars)

- **Decision Process**:
  - 0 if empty
  - 50 if partially documented (1-20 chars)
  - 100 if fully documented (>20 chars)

- **Identify Pain**:
  - 0 if empty
  - 50 if partially documented (1-20 chars)
  - 100 if fully documented (>20 chars)

- **Champion**:
  - 0 if not identified
  - 50 if identified but not confirmed as champion
  - 100 if confirmed as champion (contact.is_champion = true)

- **Competition**:
  - 0 if empty
  - 50 if partially documented (1-20 chars)
  - 100 if fully documented (>20 chars)

**Overall MEDPICC Score:**
```
overall_score = average(all_component_scores)
```

### Minimum Criteria
- [ ] All 7 MEDPICC components have data
- [ ] Overall MEDPICC score ≥ 60
- [ ] Economic Buyer identified
- [ ] Champion identified
- [ ] Decision process documented

### Gating Rule to Advance

**To advance from MEDPICC Qualification to Solutioning:**

```python
can_advance = (
    overall_medpicc_score >= 60 AND
    economic_buyer_id IS NOT NULL AND
    champion_id IS NOT NULL AND
    decision_process IS NOT NULL AND
    LENGTH(decision_process) > 20
)
```

**Business Logic:**
- Overall MEDPICC score must be at least 60/100 (indicates "Good" qualification)
- Economic Buyer must be identified
- Champion must be identified
- Decision Process must be documented with sufficient detail

**Blocking Reasons:**
- MEDPICC score < 60
- Economic Buyer not identified
- Champion not identified
- Decision Process not adequately documented
- Missing critical MEDPICC components

---

## Stage 3: Solutioning

### Purpose
Develop a comprehensive solution including technical architecture, user experience, and detailed implementation plans. This stage produces all artifacts needed to deliver the solution successfully.

### Stage Objectives
- Define the complete solution architecture
- Create detailed specifications
- Plan the build approach
- Prepare for demo and deployment

### Required Artifacts

| Artifact | Type | Description | Approval Required |
|----------|------|-------------|-------------------|
| **MVP Specification** | `mvp_spec` | Detailed product requirements and features | ✅ Yes |
| **Architecture Document** | `architecture` | Technical architecture and system design | ✅ Yes |
| **UX Design** | `ux_design` | User experience and interface design | ✅ Yes |
| **Build Plan** | `build_plan` | Implementation plan with timeline and tasks | ✅ Yes |
| **Test Plan** | `test_plan` | Testing strategy and test cases | ✅ Yes |
| **Demo Script** | `demo_script` | Guide for demonstrating the solution | ✅ Yes |
| **Deployment Checklist** | `deployment_checklist` | Production deployment requirements | ✅ Yes |

### Artifact Details

Each artifact must:
- Be in 'approved' status
- Have a reviewer assigned
- Be at version 1.0 or higher
- Contain complete information per templates

### Minimum Criteria
- [ ] All 7 required artifacts created
- [ ] All 7 artifacts in 'approved' status
- [ ] Technical review completed
- [ ] Solution validated with customer (informal)
- [ ] Pricing/estimate documented

### Gating Rule to Advance

**To advance from Solutioning to Proposal:**

```python
required_artifacts = [
    'mvp_spec',
    'architecture',
    'ux_design',
    'build_plan',
    'test_plan',
    'demo_script',
    'deployment_checklist'
]

can_advance = (
    all(artifact.status == 'approved' for artifact in required_artifacts) AND
    artifacts_count >= 7
)
```

**Business Logic:**
- All 7 required artifact types must exist
- Each artifact must be in 'approved' status
- Technical feasibility validated

**Blocking Reasons:**
- One or more required artifacts missing
- Any artifact not approved (in draft, review, or rejected status)
- Technical risks not mitigated
- Customer validation incomplete

---

## Stage 4: Proposal

### Purpose
Create and submit formal proposal with pricing, timeline, and terms.

### Stage Objectives
- Finalize pricing and commercial terms
- Create formal proposal document
- Present to customer stakeholders
- Address questions and concerns

### Required Artifacts

| Artifact | Type | Description | Approval Required |
|----------|------|-------------|-------------------|
| Formal Proposal | External document | Commercial proposal with SOW | Legal review |

### Minimum Criteria
- [ ] Proposal created and reviewed internally
- [ ] Pricing approved by management
- [ ] Legal review completed
- [ ] Proposal submitted to customer

### Gating Rule to Advance

**To advance from Proposal to Negotiation:**

Manual approval required after proposal submission.

---

## Stage 5: Negotiation

### Purpose
Finalize terms, address concerns, and work toward contract signature.

### Stage Objectives
- Negotiate commercial terms
- Address technical/legal concerns
- Finalize contract terms
- Obtain necessary approvals

### Required Artifacts

Contract negotiations may require:
- Revised proposal versions
- Addendums
- MSA/SOW revisions

### Minimum Criteria
- [ ] All customer concerns addressed
- [ ] Commercial terms agreed upon
- [ ] Legal terms finalized
- [ ] Internal approvals obtained

### Gating Rule to Advance

**To advance to Closed Won:**

Manual approval required after contract signature.

---

## Stage 6: Closed Won

### Purpose
Opportunity successfully closed. Begin project kickoff and delivery.

### Stage Objectives
- Execute contract
- Begin project delivery
- Transition to delivery team

### Post-Close Actions
- [ ] Contract signed
- [ ] Project kickoff scheduled
- [ ] Delivery team briefed
- [ ] Customer onboarding initiated

---

## Stage 7: Closed Lost

### Purpose
Opportunity lost. Document reasons for future learning.

### Stage Objectives
- Document loss reasons
- Capture lessons learned
- Maintain customer relationship

### Post-Close Actions
- [ ] Loss reason documented
- [ ] Competitive intel captured
- [ ] Follow-up plan created (if appropriate)
- [ ] Post-mortem completed

---

## Priority Calculation

Opportunity priority is calculated based on weighted value:

```python
weighted_value = value * (probability / 100) * (medpicc_score / 100)

if weighted_value >= 150000:
    priority = 'critical'
elif weighted_value >= 75000:
    priority = 'high'
elif weighted_value >= 30000:
    priority = 'medium'
else:
    priority = 'low'
```

### Priority Levels

| Priority | Weighted Value | Color | Actions |
|----------|----------------|-------|---------|
| **Critical** | ≥ $150,000 | Red | Daily review, executive visibility |
| **High** | $75,000 - $149,999 | Orange | Weekly review, management attention |
| **Medium** | $30,000 - $74,999 | Yellow | Bi-weekly review, standard process |
| **Low** | < $30,000 | Gray | Monthly review, minimal overhead |

---

## Workflow Automation Triggers

The system supports automated actions based on stage changes and other events:

### Trigger Events
- `stage_change`: When opportunity advances to new stage
- `artifact_approved`: When artifact approval status changes
- `task_completed`: When task is marked complete
- `score_change`: When MEDPICC score changes significantly

### Example Automations

**On Stage Change to MEDPICC Qualification:**
- Create task: "Complete MEDPICC assessment"
- Assign to opportunity owner
- Set due date: 7 days

**On Stage Change to Solutioning:**
- Create 7 tasks for required artifacts
- Assign to appropriate team members
- Notify architect and UX designer

**On Artifact Approved:**
- Check if all required artifacts approved
- If yes, notify owner that stage can advance
- Send notification to reviewer

**On MEDPICC Score < 50:**
- Create alert for BDM
- Flag opportunity for review
- Schedule check-in meeting

---

## Reporting and Analytics

### Key Metrics by Stage

| Metric | Description | Target |
|--------|-------------|--------|
| **Conversion Rate** | % advancing to next stage | > 60% |
| **Average Time in Stage** | Days spent in each stage | < 30 days |
| **MEDPICC Score Trend** | Score improvement over time | Increasing |
| **Win Rate** | Closed Won / (Won + Lost) | > 40% |

### Stage-Specific KPIs

**Pre-Qualification:**
- Time to Intent Brief approval: < 7 days
- Pre-qualification conversion rate: > 70%

**MEDPICC Qualification:**
- Average MEDPICC score: > 70
- Time to qualification: < 14 days
- Qualification conversion rate: > 60%

**Solutioning:**
- Artifact approval rate: > 90%
- Time to complete solution: < 30 days
- Solutioning conversion rate: > 75%

---

## Best Practices

### For BDMs
1. **Don't rush stages**: Ensure proper qualification before advancing
2. **Engage reviewers early**: Get artifact feedback before formal review
3. **Keep MEDPICC current**: Update as new information is learned
4. **Document everything**: Use artifacts to capture knowledge
5. **Monitor priority**: High-priority opportunities need more attention

### For Reviewers
1. **Provide timely feedback**: Review artifacts within 48 hours
2. **Be thorough but practical**: Balance quality with velocity
3. **Use templates**: Leverage artifact templates for consistency
4. **Coach BDMs**: Help them improve their approach
5. **Escalate risks**: Flag concerns early

### For Admins
1. **Monitor pipeline health**: Track conversion rates by stage
2. **Enforce gates**: Don't allow stage skipping
3. **Maintain data quality**: Regular cleanup and validation
4. **Tune scoring**: Adjust MEDPICC thresholds as needed
5. **Automate workflows**: Create triggers to reduce manual work

---

## Change Log

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-01-05 | Initial version | System Admin |

---

## References

- [MEDPICC Methodology](https://www.meddicc.com/)
- [ADLC Artifact Templates](./adlc-artifact-templates.md)
- [Opportunity Management Guide](./opportunity-management.md) (TBD)
