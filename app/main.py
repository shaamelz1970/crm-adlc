"""
CRM-ADLC FastAPI Application

A multi-tenant CRM with MEDPICC qualification and ADLC artifact management.
This is a minimal scaffold demonstrating core functionality.
"""

from fastapi import FastAPI, Request, HTTPException, Form
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse, JSONResponse
from pydantic import BaseModel
from typing import List, Optional
from datetime import date, datetime
import os

# Initialize FastAPI app
app = FastAPI(
    title="CRM-ADLC",
    description="Multi-tenant CRM with MEDPICC qualification and ADLC integration",
    version="0.1.0"
)

# Mount static files
app.mount("/static", StaticFiles(directory="static"), name="static")

# Configure Jinja2 templates
templates = Jinja2Templates(directory="templates")

# ============================================
# Data Models
# ============================================

class OpportunityBase(BaseModel):
    id: str
    name: str
    company: str
    stage: str
    value: Optional[float] = None
    probability: Optional[int] = None
    owner: str
    expected_close_date: Optional[date] = None
    medpicc_score: Optional[int] = 0

class OpportunityDetail(OpportunityBase):
    description: Optional[str] = None
    budget_range: Optional[str] = None
    timeline: Optional[str] = None
    decision_maker: Optional[str] = None
    pain_points: Optional[str] = None
    initial_interest_level: Optional[str] = None
    
    # MEDPICC fields
    metrics: Optional[str] = None
    economic_buyer: Optional[str] = None
    decision_criteria: Optional[str] = None
    decision_process: Optional[str] = None
    identify_pain: Optional[str] = None
    champion: Optional[str] = None
    
    # Artifacts
    artifacts: List[dict] = []

class PriorityRequest(BaseModel):
    opportunity_id: str
    value: float
    probability: int
    medpicc_score: int

class StageChangeRequest(BaseModel):
    opportunity_id: str
    current_stage: str
    new_stage: str
    artifacts_completed: List[str]

# ============================================
# Sample Data (In-memory for demonstration)
# ============================================

SAMPLE_OPPORTUNITIES = [
    OpportunityDetail(
        id="opp-001",
        name="Enterprise CRM Implementation",
        company="Acme Corp",
        stage="medpicc_qualification",
        value=250000.00,
        probability=65,
        owner="Jane Smith (BDM)",
        expected_close_date=date(2026, 3, 15),
        medpicc_score=67,
        description="Large enterprise customer looking to replace legacy CRM system",
        budget_range="$200k-$300k",
        timeline="Q1 2026 implementation",
        decision_maker="CTO - John Davis",
        pain_points="Current system lacks mobile support and real-time analytics",
        initial_interest_level="High",
        metrics="Improve sales team efficiency by 30%, reduce data entry time by 50%",
        economic_buyer="CFO - Sarah Johnson",
        decision_criteria="Cloud-based, Mobile-first, Integration with existing ERP",
        decision_process="Tech evaluation (2 weeks) → Vendor selection (1 week) → Contract negotiation",
        identify_pain="Sales reps spending 40% of time on data entry instead of selling",
        champion="VP Sales - Mike Wilson",
        artifacts=[
            {"type": "intent_brief", "status": "approved", "title": "Acme Corp Intent Brief"},
            {"type": "mvp_spec", "status": "submitted", "title": "MVP Feature Specification"},
        ]
    ),
    OpportunityDetail(
        id="opp-002",
        name="Marketing Automation Platform",
        company="TechStart Inc",
        stage="pre_qualify",
        value=85000.00,
        probability=30,
        owner="Bob Johnson (BDM)",
        expected_close_date=date(2026, 4, 30),
        medpicc_score=0,
        description="Startup needs marketing automation for lead nurturing",
        budget_range="$50k-$100k",
        timeline="Q2 2026",
        decision_maker="CMO - Lisa Chen",
        pain_points="Manual email campaigns, no lead scoring",
        initial_interest_level="Medium",
        artifacts=[]
    ),
    OpportunityDetail(
        id="opp-003",
        name="Cloud Migration Services",
        company="Global Finance Ltd",
        stage="solutioning",
        value=500000.00,
        probability=80,
        owner="Alice Williams (BDM)",
        expected_close_date=date(2026, 2, 28),
        medpicc_score=100,
        description="Financial services company migrating to cloud infrastructure",
        budget_range="$400k-$600k",
        timeline="Q1 2026 start",
        decision_maker="CIO - Robert Lee",
        pain_points="Legacy infrastructure high maintenance cost and limited scalability",
        initial_interest_level="Very High",
        metrics="Reduce infrastructure costs by 40%, improve uptime to 99.99%",
        economic_buyer="CEO - Amanda Brown",
        decision_criteria="Security certifications, Proven financial services experience, 24/7 support",
        decision_process="Security audit → Board approval → Contract signing",
        identify_pain="Current infrastructure costing $2M annually with frequent outages",
        champion="Head of Infrastructure - David Kim",
        artifacts=[
            {"type": "intent_brief", "status": "approved", "title": "Cloud Migration Intent"},
            {"type": "mvp_spec", "status": "approved", "title": "Phase 1 Migration Plan"},
            {"type": "architecture", "status": "approved", "title": "Target Architecture"},
            {"type": "build_plan", "status": "submitted", "title": "Migration Build Plan"},
        ]
    ),
]

# ============================================
# Routes
# ============================================

@app.get("/", response_class=HTMLResponse)
async def dashboard(request: Request):
    """
    Dashboard view showing all opportunities
    """
    return templates.TemplateResponse(
        "dashboard.html",
        {
            "request": request,
            "opportunities": SAMPLE_OPPORTUNITIES,
            "page_title": "CRM Dashboard"
        }
    )

@app.get("/opportunity/{opportunity_id}", response_class=HTMLResponse)
async def opportunity_detail(request: Request, opportunity_id: str):
    """
    Opportunity detail view with MEDPICC information and artifacts
    """
    # Find opportunity by ID
    opportunity = next(
        (opp for opp in SAMPLE_OPPORTUNITIES if opp.id == opportunity_id),
        None
    )
    
    if not opportunity:
        raise HTTPException(status_code=404, detail="Opportunity not found")
    
    # Define stage progression
    stage_progression = {
        "pre_qualify": "medpicc_qualification",
        "medpicc_qualification": "solutioning",
        "solutioning": "closed_won"
    }
    
    next_stage = stage_progression.get(opportunity.stage)
    
    # Define required artifacts per stage
    required_artifacts = {
        "pre_qualify": [],
        "medpicc_qualification": ["intent_brief"],
        "solutioning": ["intent_brief", "mvp_spec", "architecture"]
    }
    
    current_required = required_artifacts.get(opportunity.stage, [])
    
    return templates.TemplateResponse(
        "opportunity.html",
        {
            "request": request,
            "opportunity": opportunity,
            "next_stage": next_stage,
            "required_artifacts": current_required,
            "page_title": f"Opportunity: {opportunity.name}"
        }
    )

@app.post("/api/compute-priority")
async def compute_priority(priority_req: PriorityRequest):
    """
    Compute priority score for an opportunity based on value, probability, and MEDPICC score
    
    Priority formula: (value * probability * (1 + medpicc_score/100)) / 100
    """
    try:
        # Normalize inputs
        value = max(0, priority_req.value)
        probability = max(0, min(100, priority_req.probability))
        medpicc_score = max(0, min(100, priority_req.medpicc_score))
        
        # Calculate priority score
        priority_score = (value * probability * (1 + medpicc_score / 100)) / 100
        
        # Determine priority level
        if priority_score >= 100000:
            priority_level = "critical"
        elif priority_score >= 50000:
            priority_level = "high"
        elif priority_score >= 20000:
            priority_level = "medium"
        else:
            priority_level = "low"
        
        return JSONResponse({
            "opportunity_id": priority_req.opportunity_id,
            "priority_score": round(priority_score, 2),
            "priority_level": priority_level,
            "inputs": {
                "value": value,
                "probability": probability,
                "medpicc_score": medpicc_score
            }
        })
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/api/stage-change")
async def request_stage_change(stage_req: StageChangeRequest):
    """
    Request to advance opportunity to next stage
    
    Validates that required artifacts are completed before allowing stage progression
    """
    # Define gating requirements
    required_artifacts_by_stage = {
        "medpicc_qualification": ["intent_brief"],
        "solutioning": ["intent_brief", "mvp_spec"],
        "closed_won": ["intent_brief", "mvp_spec", "architecture", "build_plan", "test_plan"]
    }
    
    # Check if stage transition is valid
    valid_transitions = {
        "pre_qualify": ["medpicc_qualification"],
        "medpicc_qualification": ["solutioning", "closed_lost"],
        "solutioning": ["closed_won", "closed_lost"]
    }
    
    if stage_req.new_stage not in valid_transitions.get(stage_req.current_stage, []):
        raise HTTPException(
            status_code=400,
            detail=f"Invalid stage transition from {stage_req.current_stage} to {stage_req.new_stage}"
        )
    
    # Check artifact requirements (only for forward progression)
    if stage_req.new_stage in required_artifacts_by_stage:
        required = set(required_artifacts_by_stage[stage_req.new_stage])
        completed = set(stage_req.artifacts_completed)
        missing = required - completed
        
        if missing:
            return JSONResponse(
                status_code=400,
                content={
                    "success": False,
                    "message": f"Cannot advance to {stage_req.new_stage}. Missing required artifacts: {', '.join(missing)}",
                    "missing_artifacts": list(missing)
                }
            )
    
    # Stage change approved
    return JSONResponse({
        "success": True,
        "message": f"Stage change approved from {stage_req.current_stage} to {stage_req.new_stage}",
        "opportunity_id": stage_req.opportunity_id,
        "new_stage": stage_req.new_stage
    })

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "crm-adlc"}

# ============================================
# Main Entry Point
# ============================================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
