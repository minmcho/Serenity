"""
VitalPath AI - User & WellnessProfile Models
"""
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime


class WellnessProfileBase(BaseModel):
    """Base wellness profile schema."""
    dietary_restrictions: List[str] = []
    preferences: List[str] = []
    goals: List[str] = []
    activity_level: str = "moderate"
    languages: List[str] = ["en"]


class WellnessProfile(WellnessProfileBase):
    """Complete wellness profile with metadata."""
    user_id: str
    id: str
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class WellnessProfileCreate(BaseModel):
    """Schema for creating a new wellness profile."""
    dietary_restrictions: List[str] = []
    preferences: List[str] = []
    goals: List[str] = []
    activity_level: str = "moderate"
    languages: List[str] = ["en"]


class WellnessProfileUpdate(BaseModel):
    """Schema for updating wellness profile."""
    dietary_restrictions: Optional[List[str]] = None
    preferences: Optional[List[str]] = None
    goals: Optional[List[str]] = None
    activity_level: Optional[str] = None
    languages: Optional[List[str]] = None
