"""
VitalPath AI - Database Models for Supabase PostgreSQL
"""
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from enum import Enum


class SessionType(str, Enum):
    CHAT = "chat"
    VIDEO_MEAL = "video_meal"
    VIDEO_EXERCISE = "video_exercise"
    HABIT_CHECKIN = "habit_checkin"
    MINDFULNESS = "mindfulness"


class WellnessSessionBase(BaseModel):
    """Base wellness session schema."""
    session_type: SessionType
    content: str
    mood_before: Optional[int] = Field(None, ge=1, le=10)
    mood_after: Optional[int] = Field(None, ge=1, le=10)
    duration_seconds: Optional[int] = None


class WellnessSession(WellnessSessionBase):
    """Complete wellness session with metadata."""
    id: str
    user_id: str
    streak_count: int
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class WellnessSessionCreate(BaseModel):
    """Schema for creating a new wellness session."""
    session_type: SessionType
    content: str
    mood_before: Optional[int] = None
    mood_after: Optional[int] = None
    duration_seconds: Optional[int] = None


class WearableDeviceType(str, Enum):
    APPLE_HEALTH = "apple_health"
    FITBIT = "fitbit"
    GARMIN = "garmin"
    OURA = "oura"


class WearableConnectionBase(BaseModel):
    """Base wearable connection schema."""
    device_type: WearableDeviceType
    is_connected: bool = True
    last_synced: datetime


class WearableConnection(WearableConnectionBase):
    """Complete wearable connection with metrics."""
    id: str
    user_id: str
    steps_today: int = 0
    heart_rate_avg: float = 0.0
    calories_burned: int = 0
    sleep_hours: Optional[float] = None
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class WearableDataSync(BaseModel):
    """Schema for syncing wearable data."""
    steps: Optional[int] = None
    heart_rate_avg: Optional[float] = None
    calories_burned: Optional[int] = None
    sleep_hours: Optional[float] = None
    active_minutes: Optional[int] = None


class VideoAnalysisTask(BaseModel):
    """Video analysis task tracking."""
    id: str
    user_id: str
    video_url: str
    analysis_type: str  # "meal" or "exercise"
    status: str  # "pending", "processing", "completed", "failed"
    result: Optional[dict] = None
    created_at: datetime
    completed_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True


class CrisisEvent(BaseModel):
    """Crisis event logging (hashed, no PHI)."""
    id: str
    user_hash: str
    severity: str
    region: str
    keywords_detected: List[str]
    helpline_shown: bool
    created_at: datetime
    
    class Config:
        from_attributes = True
