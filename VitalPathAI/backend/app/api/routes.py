"""
VitalPath AI - REST API Routes
"""
from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel
from typing import Optional

router = APIRouter()


class CrisisEscalationRequest(BaseModel):
    user_id: str
    severity: str
    region: Optional[str] = "US"
    notes: Optional[str] = None


class CrisisEscalationResponse(BaseModel):
    status: str
    helpline_number: str
    message: str


@router.post("/crisis/escalate", response_model=CrisisEscalationResponse)
async def escalate_crisis(request: CrisisEscalationRequest):
    """Manually escalate a crisis situation."""
    from app.config import settings
    
    helplines = {
        "US": settings.crisis_us,
        "TH": settings.crisis_th,
        "MM": settings.crisis_mm,
        "JP": settings.crisis_jp,
    }
    
    helpline = helplines.get(request.region.upper(), settings.crisis_us)
    
    # Log crisis event (hashed, no PHI)
    import hashlib
    hashed_user = hashlib.sha256(request.user_id.encode()).hexdigest()
    
    print(f"CRISIS_ESCALATION: user={hashed_user}, severity={request.severity}, region={request.region}")
    
    return CrisisEscalationResponse(
        status="escalated",
        helpline_number=helpline,
        message="Please contact the helpline immediately. You are not alone."
    )


@router.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy"}


@router.post("/webhooks/supabase")
async def supabase_webhook(request: Request):
    """Handle Supabase webhook events."""
    # TODO: Implement webhook handler for auth events, database changes
    return {"status": "received"}
