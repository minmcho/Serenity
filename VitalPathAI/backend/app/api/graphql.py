"""
VitalPath AI - GraphQL Schema with Strawberry
"""
import strawberry
from typing import List, Optional, AsyncGenerator
from datetime import datetime
import asyncio

from app.core.safety import SafetyValidator
from app.services.ai_orchestrator import AIOrchestrator
from app.tasks.video_analysis import analyze_video_task


# GraphQL Types
@strawberry.type
class WellnessProfile:
    user_id: str
    preferences: List[str]
    dietary_restrictions: List[str]
    goals: List[str]
    created_at: datetime
    updated_at: datetime


@strawberry.type
class WellnessSession:
    id: str
    user_id: str
    session_type: str
    content: str
    mood_before: Optional[int]
    mood_after: Optional[int]
    streak_count: int
    created_at: datetime


@strawberry.type
class WearableConnection:
    id: str
    user_id: str
    device_type: str
    steps_today: int
    heart_rate_avg: float
    last_synced: datetime


@strawberry.type
class ChatResponse:
    message: str
    safety_flag: bool
    crisis_detected: bool
    suggested_actions: List[str]


@strawberry.type
class VideoAnalysisTask:
    task_id: str
    status: str
    video_url: str
    analysis_type: str


@strawberry.type
class VideoAnalysisResult:
    task_id: str
    nutrition_estimate: Optional[str]
    form_feedback: Optional[str]
    safety_flag: bool
    wellness_message: str


@strawberry.type
class CrisisResource:
    region: str
    hotline_number: str
    hotline_name: str


# Input Types
@strawberry.input
class SessionInput:
    session_type: str
    content: str
    mood_before: Optional[int] = None
    mood_after: Optional[int] = None


@strawberry.input
class MessageInput:
    message: str
    language: str = "en"


# Query Resolvers
@strawberry.type
class Query:
    @strawberry.field
    async def user_profile(self, info: strawberry.Info) -> Optional[WellnessProfile]:
        """Get current user's wellness profile."""
        # TODO: Implement Supabase query
        return None

    @strawberry.field
    async def wellness_sessions(
        self, 
        info: strawberry.Info, 
        limit: int = 10
    ) -> List[WellnessSession]:
        """Get user's recent wellness sessions."""
        # TODO: Implement Supabase query
        return []

    @strawberry.field
    async def wearable_data(self, info: strawberry.Info) -> Optional[WearableConnection]:
        """Get wearable device data."""
        # TODO: Implement Supabase query
        return None

    @strawberry.field
    async def crisis_resources(
        self, 
        info: strawberry.Info, 
        region: str = "US"
    ) -> CrisisResource:
        """Get crisis helpline for specific region."""
        from app.config import settings
        
        resources = {
            "US": CrisisResource(
                region="US",
                hotline_number=settings.crisis_us,
                hotline_name="Suicide & Crisis Lifeline"
            ),
            "TH": CrisisResource(
                region="TH",
                hotline_number=settings.crisis_th,
                hotline_name="Thai Mental Health Hotline"
            ),
            "MM": CrisisResource(
                region="MM",
                hotline_number=settings.crisis_mm,
                hotline_name="Myanmar Mental Health Support"
            ),
            "JP": CrisisResource(
                region="JP",
                hotline_number=settings.crisis_jp,
                hotline_name="Inochi-no-Denwa"
            ),
        }
        
        return resources.get(region.upper(), resources["US"])


# Mutation Resolvers
@strawberry.type
class Mutation:
    @strawberry.mutation
    async def send_message(
        self, 
        info: strawberry.Info, 
        input: MessageInput
    ) -> ChatResponse:
        """Send a message to the AI wellness coach."""
        # Step 1: Input Safety Check
        safety_result = SafetyValidator.validate_input(input.message)
        
        if safety_result["crisis_detected"]:
            return ChatResponse(
                message="I'm concerned about your safety. Please reach out to a crisis helpline immediately.",
                safety_flag=True,
                crisis_detected=True,
                suggested_actions=["Call helpline", "Contact loved one", "Seek professional help"]
            )
        
        if safety_result["blocked"]:
            return ChatResponse(
                message="Let's focus on wellness and lifestyle guidance. I can't provide medical advice.",
                safety_flag=True,
                crisis_detected=False,
                suggested_actions=["Ask about healthy habits", "Discuss wellness goals"]
            )
        
        # Step 2: Get AI Response
        try:
            ai_response = await AIOrchestrator.process_text(
                message=input.message,
                language=input.language
            )
            
            # Step 3: Output Safety Check
            output_safety = SafetyValidator.validate_output(ai_response)
            
            if output_safety["blocked"]:
                # Regenerate with stricter constraints
                ai_response = await AIOrchestrator.process_text(
                    message=input.message,
                    language=input.language,
                    strict_wellness_mode=True
                )
            
            return ChatResponse(
                message=ai_response,
                safety_flag=False,
                crisis_detected=False,
                suggested_actions=[]
            )
            
        except Exception as e:
            # Fallback to cached wellness tips
            return ChatResponse(
                message="Here's a wellness tip: Take three deep breaths and notice how you feel right now.",
                safety_flag=False,
                crisis_detected=False,
                suggested_actions=["Try breathing exercise", "Log your mood"]
            )

    @strawberry.mutation
    async def upload_video(
        self,
        info: strawberry.Info,
        video_url: str,
        analysis_type: str
    ) -> VideoAnalysisTask:
        """Upload video for meal or exercise analysis."""
        # Validate analysis type
        if analysis_type not in ["meal", "exercise"]:
            raise ValueError("Analysis type must be 'meal' or 'exercise'")
        
        # Create Celery task
        task = analyze_video_task.delay(video_url, analysis_type)
        
        return VideoAnalysisTask(
            task_id=task.id,
            status="processing",
            video_url=video_url,
            analysis_type=analysis_type
        )

    @strawberry.mutation
    async def log_session(
        self,
        info: strawberry.Info,
        session_input: SessionInput
    ) -> WellnessSession:
        """Log a new wellness session."""
        # TODO: Implement Supabase insert
        return WellnessSession(
            id="session_123",
            user_id="user_123",
            session_type=session_input.session_type,
            content=session_input.content,
            mood_before=session_input.mood_before,
            mood_after=session_input.mood_after,
            streak_count=5,
            created_at=datetime.now()
        )

    @strawberry.mutation
    async def update_goals(
        self,
        info: strawberry.Info,
        goals: List[str]
    ) -> WellnessProfile:
        """Update user wellness goals."""
        # TODO: Implement Supabase update
        return WellnessProfile(
            user_id="user_123",
            preferences=[],
            dietary_restrictions=[],
            goals=goals,
            created_at=datetime.now(),
            updated_at=datetime.now()
        )


# Subscription Resolvers
@strawberry.type
class Subscription:
    @strawberry.subscription
    async def video_analysis_result(
        self,
        task_id: str
    ) -> AsyncGenerator[VideoAnalysisResult, None]:
        """Subscribe to video analysis results."""
        # Poll for task completion
        while True:
            # TODO: Get task status from Redis/Celery
            await asyncio.sleep(2)
            
            yield VideoAnalysisResult(
                task_id=task_id,
                nutrition_estimate="High Protein, Moderate Carbs",
                form_feedback=None,
                safety_flag=False,
                wellness_message="Great balance of greens and protein! 🥗"
            )
            break

    @strawberry.subscription
    async def chat_stream(
        self,
        message_id: str
    ) -> AsyncGenerator[str, None]:
        """Stream chat response tokens."""
        # TODO: Implement streaming from AI
        chunks = ["Hello", " there", "! ", "How", " can", " I", " help", "?"]
        for chunk in chunks:
            await asyncio.sleep(0.1)
            yield chunk


# Create Schema
schema = strawberry.Schema(query=Query, mutation=Mutation, subscription=Subscription)
