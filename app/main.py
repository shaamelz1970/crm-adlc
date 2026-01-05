"""
CRM-ADLC FastAPI Application
Multi-tenant CRM with MEDPICC qualification and ADLC methodology
"""

from fastapi import FastAPI, Request, Form, HTTPException
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from typing import Optional
from datetime import datetime, date
import os
from pathlib import Path

# Initialize FastAPI app
app = FastAPI(
    title="CRM-ADLC",
    description="Multi-tenant CRM with MEDPICC and ADLC methodology",
    version="1.0.0"
)

# Setup static files and templates
BASE_DIR = Path(__file__).resolve().parent.parent
app.mount("/static", StaticFiles(directory=str(BASE_DIR / "static")), name="static")
templates = Jinja2Templates(directory=str(BASE_DIR / "templates"))

# Sample data for demonstration (in production, this would come from Supabase)
SAMPLE_OPPORTUNITIES = [
    {
        "id": "550e8400-e29b-41d4-a716-446655440001",
        "name": "Acme Corp - Enterprise CRM",
        "company": "Acme Corp",
        "stage": "medpicc_qualification",
        "value": 250000.00,
        "currency": "USD",
        "probability": 60,
        "expected_close_date": date(2026, 3, 15),
        "priority": "high",
        "owner": "BDM User",
        "medpicc": {
            "metrics_score": 80,
            "economic_buyer_score": 100,
            "decision_criteria_score": 75,
            "decision_process_score": 50,
            "identify_pain_score": 90,
            "champion_score": 100,
            "competition_score": 60,
            "overall_score": 79
        },
        "description": "Enterprise CRM solution for Acme Corp's sales team",
        "metrics": "Reduce sales cycle by 30%, increase conversion rate by 25%",
        "economic_buyer": "Jane Smith, VP Sales",
        "decision_criteria": "Integration with existing tools, ease of use, scalability",
        "decision_process": "Technical evaluation → Pilot program → Board approval",
        "identify_pain": "Current manual process losing leads, no visibility into pipeline",
        "champion": "John Doe, Sales Director",
        "competition": "Salesforce, HubSpot (existing partial deployment)"
    },
    {
        "id": "550e8400-e29b-41d4-a716-446655440002",
        "name": "TechStart Inc - MVP Development",
        "company": "TechStart Inc",
        "stage": "pre_qualify",
        "value": 75000.00,
        "currency": "USD",
        "probability": 30,
        "expected_close_date": date(2026, 2, 28),
        "priority": "medium",
        "owner": "BDM User",
        "medpicc": {
            "metrics_score": 50,
            "economic_buyer_score": 0,
            "decision_criteria_score": 25,
            "decision_process_score": 0,
            "identify_pain_score": 75,
            "champion_score": 50,
            "competition_score": 25,
            "overall_score": 32
        },
        "description": "Build MVP for new SaaS product",
        "metrics": "Time to market in 3 months, under $100k budget",
        "economic_buyer": "Not yet identified",
        "decision_criteria": "Cost, timeline, technical expertise",
        "decision_process": "Unknown",
        "identify_pain": "Need to validate product-market fit quickly with limited resources",
        "champion": "Mike Johnson, CTO (potential)",
        "competition": "Internal dev team, offshore vendors"
    },
    {
        "id": "550e8400-e29b-41d4-a716-446655440003",
        "name": "Global Systems - Digital Transformation",
        "company": "Global Systems Ltd",
        "stage": "solutioning",
        "value": 500000.00,
        "currency": "USD",
        "probability": 75,
        "expected_close_date": date(2026, 4, 30),
        "priority": "critical",
        "owner": "BDM User",
        "medpicc": {
            "metrics_score": 95,
            "economic_buyer_score": 100,
            "decision_criteria_score": 100,
            "decision_process_score": 100,
            "identify_pain_score": 100,
            "champion_score": 100,
            "competition_score": 80,
            "overall_score": 96
        },
        "description": "Complete digital transformation of legacy systems",
        "metrics": "ROI of 200% in 2 years, reduce operational costs by 40%",
        "economic_buyer": "Sarah Chen, CFO",
        "decision_criteria": "Proven track record, cloud-native, security certifications",
        "decision_process": "RFP → Short list → POC → Final presentation → Contract",
        "identify_pain": "Legacy systems causing downtime, security risks, high maintenance costs",
        "champion": "David Park, Head of IT",
        "competition": "IBM, Accenture (preferred vendor status)"
    }
]

SAMPLE_ARTIFACTS = {
    "550e8400-e29b-41d4-a716-446655440001": [
        {"type": "intent_brief", "status": "approved", "title": "Intent Brief - Acme CRM"},
        {"type": "mvp_spec", "status": "review", "title": "MVP Specification v2.1"}
    ],
    "550e8400-e29b-41d4-a716-446655440003": [
        {"type": "intent_brief", "status": "approved", "title": "Intent Brief - Digital Transformation"},
        {"type": "mvp_spec", "status": "approved", "title": "MVP Specification - Phase 1"},
        {"type": "architecture", "status": "approved", "title": "Solution Architecture"},
        {"type": "ux_design", "status": "review", "title": "UX Design System"},
        {"type": "build_plan", "status": "draft", "title": "Build Plan - Q1 2026"}
    ]
}

# Helper functions
def get_opportunity_by_id(opp_id: str):
    """Get opportunity by ID from sample data"""
    for opp in SAMPLE_OPPORTUNITIES:
        if opp["id"] == opp_id:
            return opp
    return None

def get_medpicc_score_color(score: int) -> str:
    """Return CSS class based on MEDPICC score"""
    if score >= 80:
        return "success"
    elif score >= 60:
        return "warning"
    else:
        return "danger"

def get_priority_badge(priority: str) -> str:
    """Return CSS class for priority badge"""
    priority_map = {
        "critical": "danger",
        "high": "warning",
        "medium": "info",
        "low": "secondary"
    }
    return priority_map.get(priority, "secondary")

def get_stage_display_name(stage: str) -> str:
    """Convert stage slug to display name"""
    stage_map = {
        "pre_qualify": "Pre-Qualification",
        "medpicc_qualification": "MEDPICC Qualification",
        "solutioning": "Solutioning",
        "proposal": "Proposal",
        "negotiation": "Negotiation",
        "closed_won": "Closed Won",
        "closed_lost": "Closed Lost"
    }
    return stage_map.get(stage, stage)

# Add helper functions to Jinja2 templates
templates.env.globals.update(
    get_medpicc_score_color=get_medpicc_score_color,
    get_priority_badge=get_priority_badge,
    get_stage_display_name=get_stage_display_name
)

# Routes

@app.get("/", response_class=HTMLResponse)
async def dashboard(request: Request):
    """Dashboard showing all opportunities"""
    return templates.TemplateResponse(
        "dashboard.html",
        {
            "request": request,
            "opportunities": SAMPLE_OPPORTUNITIES,
            "page_title": "Dashboard"
        }
    )

@app.get("/opportunity/{opportunity_id}", response_class=HTMLResponse)
async def opportunity_detail(request: Request, opportunity_id: str):
    """Opportunity detail page with MEDPICC panel"""
    opportunity = get_opportunity_by_id(opportunity_id)
    
    if not opportunity:
        raise HTTPException(status_code=404, detail="Opportunity not found")
    
    artifacts = SAMPLE_ARTIFACTS.get(opportunity_id, [])
    
    # Determine if stage can be advanced
    can_advance = False
    next_stage = None
    gating_message = ""
    
    current_stage = opportunity["stage"]
    medpicc_score = opportunity["medpicc"]["overall_score"]
    
    if current_stage == "pre_qualify":
        # Check for Intent Brief
        has_intent_brief = any(a["type"] == "intent_brief" and a["status"] == "approved" for a in artifacts)
        if has_intent_brief:
            can_advance = True
            next_stage = "medpicc_qualification"
        else:
            gating_message = "Requires approved Intent Brief artifact"
    
    elif current_stage == "medpicc_qualification":
        # Check MEDPICC score
        if medpicc_score >= 60:
            can_advance = True
            next_stage = "solutioning"
        else:
            gating_message = f"MEDPICC score must be >= 60 (current: {medpicc_score})"
    
    elif current_stage == "solutioning":
        # Check for all required artifacts
        required_artifacts = ["mvp_spec", "architecture", "ux_design", "build_plan", "test_plan", "demo_script", "deployment_checklist"]
        approved_artifacts = [a["type"] for a in artifacts if a["status"] == "approved"]
        missing = [a for a in required_artifacts if a not in approved_artifacts]
        
        if not missing:
            can_advance = True
            next_stage = "proposal"
        else:
            gating_message = f"Missing approved artifacts: {', '.join(missing)}"
    
    return templates.TemplateResponse(
        "opportunity.html",
        {
            "request": request,
            "opportunity": opportunity,
            "artifacts": artifacts,
            "can_advance": can_advance,
            "next_stage": next_stage,
            "gating_message": gating_message,
            "page_title": opportunity["name"]
        }
    )

@app.post("/api/compute-priority")
async def compute_priority(
    opportunity_id: str = Form(...),
    value: float = Form(...),
    probability: int = Form(...),
    medpicc_score: int = Form(...)
):
    """
    Compute priority based on opportunity metrics
    Formula: (value * probability/100 * medpicc_score/100) / 10000
    """
    try:
        # Calculate weighted score
        weighted_value = value * (probability / 100) * (medpicc_score / 100)
        
        # Determine priority
        if weighted_value >= 150000:
            priority = "critical"
        elif weighted_value >= 75000:
            priority = "high"
        elif weighted_value >= 30000:
            priority = "medium"
        else:
            priority = "low"
        
        return {
            "success": True,
            "priority": priority,
            "weighted_value": round(weighted_value, 2)
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/api/stage-change")
async def stage_change(
    opportunity_id: str = Form(...),
    new_stage: str = Form(...)
):
    """
    Change opportunity stage (with gating validation)
    """
    opportunity = get_opportunity_by_id(opportunity_id)
    
    if not opportunity:
        raise HTTPException(status_code=404, detail="Opportunity not found")
    
    # In production, validate gating rules and update database
    # For now, just return success
    return {
        "success": True,
        "message": f"Stage changed to {get_stage_display_name(new_stage)}",
        "new_stage": new_stage
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "version": "1.0.0"
    }

if __name__ == "__main__":
    import uvicorn
    
    port = int(os.getenv("PORT", 8000))
    host = os.getenv("HOST", "0.0.0.0")
    
    uvicorn.run(
        "main:app",
        host=host,
        port=port,
        reload=True
    )
