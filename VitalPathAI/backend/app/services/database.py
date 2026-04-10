"""
VitalPath AI - Supabase Database Service
"""
from supabase import create_client, Client
from typing import List, Optional, Dict, Any
from datetime import datetime
import structlog

from app.config import settings
from app.models.schemas import (
    WellnessProfile,
    WellnessProfileCreate,
    WellnessProfileUpdate,
    WellnessSession,
    WellnessSessionCreate,
    WearableConnection,
    WearableDataSync,
    VideoAnalysisTask,
    CrisisEvent,
)

logger = structlog.get_logger()


class SupabaseService:
    """Supabase database service for data persistence."""
    
    _client: Optional[Client] = None
    
    @classmethod
    def get_client(cls) -> Client:
        """Get or create Supabase client."""
        if cls._client is None:
            cls._client = create_client(
                settings.supabase_url,
                settings.supabase_key
            )
            logger.info("supabase_client_initialized")
        return cls._client
    
    @classmethod
    async def get_user_profile(cls, user_id: str) -> Optional[WellnessProfile]:
        """Get user's wellness profile."""
        try:
            client = cls.get_client()
            response = client.table("wellness_profiles").select("*").eq("user_id", user_id).execute()
            
            if response.data and len(response.data) > 0:
                return WellnessProfile(**response.data[0])
            return None
        except Exception as e:
            logger.error("get_profile_failed", user_id=user_id, error=str(e))
            return None
    
    @classmethod
    async def create_user_profile(
        cls, 
        user_id: str, 
        profile_data: WellnessProfileCreate
    ) -> Optional[WellnessProfile]:
        """Create a new wellness profile."""
        try:
            client = cls.get_client()
            data = profile_data.model_dump()
            data["user_id"] = user_id
            
            response = client.table("wellness_profiles").insert(data).execute()
            
            if response.data and len(response.data) > 0:
                logger.info("profile_created", user_id=user_id)
                return WellnessProfile(**response.data[0])
            return None
        except Exception as e:
            logger.error("create_profile_failed", user_id=user_id, error=str(e))
            return None
    
    @classmethod
    async def update_user_profile(
        cls, 
        user_id: str, 
        updates: WellnessProfileUpdate
    ) -> Optional[WellnessProfile]:
        """Update user's wellness profile."""
        try:
            client = cls.get_client()
            data = {k: v for k, v in updates.model_dump().items() if v is not None}
            
            response = (
                client.table("wellness_profiles")
                .update(data)
                .eq("user_id", user_id)
                .execute()
            )
            
            if response.data and len(response.data) > 0:
                logger.info("profile_updated", user_id=user_id)
                return WellnessProfile(**response.data[0])
            return None
        except Exception as e:
            logger.error("update_profile_failed", user_id=user_id, error=str(e))
            return None
    
    @classmethod
    async def log_session(
        cls, 
        user_id: str, 
        session_data: WellnessSessionCreate
    ) -> Optional[WellnessSession]:
        """Log a new wellness session."""
        try:
            client = cls.get_client()
            data = session_data.model_dump()
            data["user_id"] = user_id
            
            # Calculate streak
            streak = await cls._calculate_streak(user_id)
            data["streak_count"] = streak
            
            response = client.table("wellness_sessions").insert(data).execute()
            
            if response.data and len(response.data) > 0:
                logger.info("session_logged", user_id=user_id, session_type=session_data.session_type)
                return WellnessSession(**response.data[0])
            return None
        except Exception as e:
            logger.error("log_session_failed", user_id=user_id, error=str(e))
            return None
    
    @classmethod
    async def get_recent_sessions(
        cls, 
        user_id: str, 
        limit: int = 10
    ) -> List[WellnessSession]:
        """Get user's recent wellness sessions."""
        try:
            client = cls.get_client()
            response = (
                client.table("wellness_sessions")
                .select("*")
                .eq("user_id", user_id)
                .order("created_at", desc=True)
                .limit(limit)
                .execute()
            )
            
            return [WellnessSession(**session) for session in response.data or []]
        except Exception as e:
            logger.error("get_sessions_failed", user_id=user_id, error=str(e))
            return []
    
    @classmethod
    async def _calculate_streak(cls, user_id: str) -> int:
        """Calculate current streak count."""
        try:
            client = cls.get_client()
            # Get sessions from last 24 hours
            from datetime import timedelta
            cutoff = datetime.utcnow() - timedelta(hours=24)
            
            response = (
                client.table("wellness_sessions")
                .select("created_at")
                .eq("user_id", user_id)
                .gte("created_at", cutoff.isoformat())
                .execute()
            )
            
            if response.data and len(response.data) > 0:
                # Get previous streak
                profile = await cls.get_user_profile(user_id)
                return (profile.streak_count + 1) if profile else 1
            return 0
        except Exception as e:
            logger.error("streak_calculation_failed", error=str(e))
            return 0
    
    @classmethod
    async def sync_wearable_data(
        cls, 
        user_id: str, 
        device_type: str,
        data: WearableDataSync
    ) -> Optional[WearableConnection]:
        """Sync wearable device data."""
        try:
            client = cls.get_client()
            
            # Check if connection exists
            existing = client.table("wearable_connections").select("*").eq("user_id", user_id).eq("device_type", device_type).execute()
            
            update_data = {
                "steps_today": data.steps or 0,
                "heart_rate_avg": data.heart_rate_avg or 0.0,
                "calories_burned": data.calories_burned or 0,
                "sleep_hours": data.sleep_hours,
                "last_synced": datetime.utcnow().isoformat(),
            }
            
            if existing.data and len(existing.data) > 0:
                # Update existing
                response = (
                    client.table("wearable_connections")
                    .update(update_data)
                    .eq("user_id", user_id)
                    .eq("device_type", device_type)
                    .execute()
                )
            else:
                # Create new
                update_data["user_id"] = user_id
                update_data["device_type"] = device_type
                update_data["is_connected"] = True
                response = client.table("wearable_connections").insert(update_data).execute()
            
            if response.data and len(response.data) > 0:
                logger.info("wearable_synced", user_id=user_id, device_type=device_type)
                return WearableConnection(**response.data[0])
            return None
        except Exception as e:
            logger.error("wearable_sync_failed", user_id=user_id, error=str(e))
            return None
    
    @classmethod
    async def get_wearable_connection(cls, user_id: str) -> Optional[WearableConnection]:
        """Get user's wearable connection."""
        try:
            client = cls.get_client()
            response = (
                client.table("wearable_connections")
                .select("*")
                .eq("user_id", user_id)
                .execute()
            )
            
            if response.data and len(response.data) > 0:
                return WearableConnection(**response.data[0])
            return None
        except Exception as e:
            logger.error("get_wearable_failed", user_id=user_id, error=str(e))
            return None
    
    @classmethod
    async def create_video_task(
        cls,
        user_id: str,
        video_url: str,
        analysis_type: str
    ) -> Optional[VideoAnalysisTask]:
        """Create a video analysis task record."""
        try:
            client = cls.get_client()
            data = {
                "user_id": user_id,
                "video_url": video_url,
                "analysis_type": analysis_type,
                "status": "pending",
            }
            
            response = client.table("video_analysis_tasks").insert(data).execute()
            
            if response.data and len(response.data) > 0:
                logger.info("video_task_created", user_id=user_id, analysis_type=analysis_type)
                return VideoAnalysisTask(**response.data[0])
            return None
        except Exception as e:
            logger.error("create_video_task_failed", user_id=user_id, error=str(e))
            return None
    
    @classmethod
    async def update_video_task(
        cls,
        task_id: str,
        status: str,
        result: Optional[Dict[str, Any]] = None
    ) -> Optional[VideoAnalysisTask]:
        """Update video analysis task status."""
        try:
            client = cls.get_client()
            data = {
                "status": status,
                "result": result,
                "completed_at": datetime.utcnow().isoformat() if status in ["completed", "failed"] else None,
            }
            
            response = (
                client.table("video_analysis_tasks")
                .update(data)
                .eq("id", task_id)
                .execute()
            )
            
            if response.data and len(response.data) > 0:
                return VideoAnalysisTask(**response.data[0])
            return None
        except Exception as e:
            logger.error("update_video_task_failed", task_id=task_id, error=str(e))
            return None
    
    @classmethod
    async def log_crisis_event(
        cls,
        user_hash: str,
        severity: str,
        region: str,
        keywords_detected: List[str],
        helpline_shown: bool = True
    ) -> Optional[CrisisEvent]:
        """Log crisis event (hashed, no PHI)."""
        try:
            client = cls.get_client()
            data = {
                "user_hash": user_hash,
                "severity": severity,
                "region": region,
                "keywords_detected": keywords_detected,
                "helpline_shown": helpline_shown,
            }
            
            response = client.table("crisis_events").insert(data).execute()
            
            if response.data and len(response.data) > 0:
                logger.warning("crisis_event_logged", user_hash=user_hash[:8], severity=severity)
                return CrisisEvent(**response.data[0])
            return None
        except Exception as e:
            logger.error("log_crisis_failed", error=str(e))
            return None


# Convenience functions
async def get_user_profile(user_id: str) -> Optional[WellnessProfile]:
    return await SupabaseService.get_user_profile(user_id)


async def log_session(user_id: str, session_data: WellnessSessionCreate) -> Optional[WellnessSession]:
    return await SupabaseService.log_session(user_id, session_data)
