"""
VitalPath AI - Video Analysis Task with Qwen 3.5 VL

Processes uploaded videos for meal or exercise analysis using Celery.
"""
import cv2
import numpy as np
from typing import List, Dict
import structlog

from app.tasks.celery_app import celery_app
from app.services.ai_orchestrator import AIOrchestrator
from app.core.safety import SafetyValidator

logger = structlog.get_logger()


def extract_frames(video_url: str, max_frames: int = 10) -> List[bytes]:
    """
    Extract key frames from video file.
    
    Args:
        video_url: URL or path to video file
        max_frames: Maximum number of frames to extract
    
    Returns:
        List of JPEG-encoded frame bytes
    """
    # Download video from Supabase storage
    # TODO: Implement Supabase storage download
    video_path = video_url  # For now, assume local path
    
    cap = cv2.VideoCapture(video_path)
    frames = []
    frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    
    if frame_count == 0:
        logger.error("video_no_frames", url=video_url)
        return []
    
    # Calculate frame interval
    interval = max(1, frame_count // max_frames)
    
    current_frame = 0
    while len(frames) < max_frames:
        ret, frame = cap.read()
        if not ret:
            break
        
        # Only keep every Nth frame
        if current_frame % interval == 0:
            # Encode frame as JPEG
            _, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 80])
            frames.append(buffer.tobytes())
            logger.info("frame_extracted", frame_number=current_frame)
        
        current_frame += 1
    
    cap.release()
    logger.info("frames_extracted", total=len(frames))
    return frames


@celery_app.task(bind=True, max_retries=3)
def analyze_video_task(self, video_url: str, analysis_type: str) -> Dict:
    """
    Celery task for video analysis.
    
    Args:
        video_url: URL to video in Supabase storage
        analysis_type: "meal" or "exercise"
    
    Returns:
        Analysis results dict
    """
    try:
        logger.info(
            "video_analysis_started",
            video_url=video_url,
            analysis_type=analysis_type
        )
        
        # Step 1: Extract frames from video
        frames = extract_frames(video_url, max_frames=10)
        
        if not frames:
            logger.error("no_frames_extracted", video_url=video_url)
            return {
                "status": "error",
                "message": "Could not extract frames from video",
                "safety_flag": False
            }
        
        # Step 2: Send frames to Qwen 3.5 VL for analysis
        analysis_result = AIOrchestrator.analyze_visual(
            frames=frames,
            analysis_type=analysis_type,
            language="en"
        )
        
        # Step 3: Validate safety of analysis output
        safety_check = SafetyValidator.validate_output(analysis_result.get("analysis", ""))
        
        if safety_check["blocked"]:
            logger.warning(
                "video_analysis_blocked",
                prohibited=safety_check.get("prohibited_claims", [])
            )
            # Use fallback response
            analysis_result = AIOrchestrator._get_visual_fallback(analysis_type)
        
        # Step 4: Format response
        result = {
            "status": "completed",
            "task_id": self.request.id,
            "analysis_type": analysis_type,
            "nutrition_estimate": analysis_result.get("analysis") if analysis_type == "meal" else None,
            "form_feedback": analysis_result.get("analysis") if analysis_type == "exercise" else None,
            "safety_flag": safety_check["blocked"],
            "wellness_message": generate_wellness_message(analysis_type, analysis_result),
        }
        
        logger.info("video_analysis_completed", task_id=self.request.id)
        return result
        
    except Exception as e:
        logger.error("video_analysis_failed", error=str(e), exc_info=True)
        
        # Retry with exponential backoff
        try:
            raise self.retry(exc=e, countdown=60 * (self.request.retries + 1))
        except self.MaxRetriesExceededError:
            # Return fallback on max retries
            return {
                "status": "error",
                "task_id": self.request.id,
                "message": "Analysis unavailable. Please try again.",
                "wellness_message": "Great job staying mindful about your wellness!",
                "safety_flag": False
            }


def generate_wellness_message(analysis_type: str, analysis_result: Dict) -> str:
    """Generate encouraging wellness message based on analysis."""
    
    if analysis_type == "meal":
        messages = [
            "Great balance of greens and protein! 🥗",
            "This looks like a nourishing choice! 🌟",
            "Love the variety of colors on your plate! 🎨",
            "Mindful eating is a wonderful habit! 🙏",
        ]
    else:  # exercise
        messages = [
            "Excellent form! Keep it up! 💪",
            "Your dedication to movement is inspiring! ⭐",
            "Remember to breathe and enjoy the motion! 🧘",
            "Every workout counts toward your wellness journey! 🚀",
        ]
    
    import random
    return random.choice(messages)
