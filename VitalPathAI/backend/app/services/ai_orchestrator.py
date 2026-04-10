"""
VitalPath AI - AI Orchestrator Service

Routes requests to appropriate AI models:
- Llama 4: Text chat, empathetic responses
- Qwen 3.5: Complex reasoning, multilingual queries
- Qwen 3.5 VL: Visual analysis (meals, exercise)
"""
import httpx
from typing import Dict, List, Optional
import structlog

from app.config import settings
from app.core.safety import SafetyValidator

logger = structlog.get_logger()


class CircuitBreaker:
    """Circuit breaker pattern for AI service calls."""
    
    def __init__(self, threshold: int = 5, timeout: int = 60):
        self.failure_count = 0
        self.threshold = threshold
        self.timeout = timeout
        self.is_open = False
        self.last_failure_time: Optional[float] = None
    
    def record_success(self):
        self.failure_count = 0
        self.is_open = False
    
    def record_failure(self):
        import time
        self.failure_count += 1
        self.last_failure_time = time.time()
        
        if self.failure_count >= self.threshold:
            self.is_open = True
            logger.warning("circuit_breaker_opened", failures=self.failure_count)
    
    def can_execute(self) -> bool:
        import time
        
        if not self.is_open:
            return True
        
        # Check if timeout has passed
        if self.last_failure_time and (time.time() - self.last_failure_time) > self.timeout:
            logger.info("circuit_breaker_half_open")
            self.is_open = False
            self.failure_count = 0
            return True
        
        return False


class AIOrchestrator:
    """
    Multi-agent AI orchestration service.
    
    Routes requests to appropriate models based on:
    - Input type (text, image, video)
    - Complexity
    - Language requirements
    """
    
    _llama4_breaker = CircuitBreaker(
        threshold=settings.circuit_breaker_threshold,
        timeout=settings.circuit_breaker_timeout
    )
    
    _qwen35_breaker = CircuitBreaker(
        threshold=settings.circuit_breaker_threshold,
        timeout=settings.circuit_breaker_timeout
    )
    
    # System prompt enforcing wellness boundaries
    WELLNESS_SYSTEM_PROMPT = """You are a wellness coach, NOT a doctor. 

IMPORTANT RULES:
1. NEVER diagnose medical conditions
2. NEVER prescribe treatments or medications
3. NEVER claim to cure diseases
4. ALWAYS encourage professional medical care for health concerns
5. Focus on lifestyle, habits, nutrition, mindfulness, and motivation
6. Use supportive language: "may help", "can support", "consider trying"
7. If user mentions symptoms, suggest: "A healthcare provider can give you personalized advice"

Wellness Philosophy: "Wellness, Not Medicine"
"""
    
    @classmethod
    async def process_text(
        cls,
        message: str,
        language: str = "en",
        strict_wellness_mode: bool = False,
        context: Optional[List[str]] = None
    ) -> str:
        """
        Process text message through appropriate AI model.
        
        Args:
            message: User's message
            language: Language code (en, my, th, zh, ja, ko)
            strict_wellness_mode: Use stricter wellness constraints
            context: Previous conversation context for memory
        
        Returns:
            AI response string
        """
        # Determine which model to use
        if language in ["my", "th", "zh", "ja", "ko"]:
            # Use Qwen 3.5 for multilingual support
            return await cls._call_qwen35(
                message=message,
                language=language,
                strict_mode=strict_wellness_mode,
                context=context
            )
        else:
            # Use Llama 4 for English (faster, more empathetic)
            return await cls._call_llama4(
                message=message,
                strict_mode=strict_wellness_mode,
                context=context
            )
    
    @classmethod
    async def _call_llama4(
        cls,
        message: str,
        strict_mode: bool = False,
        context: Optional[List[str]] = None
    ) -> str:
        """Call Llama 4 API for text generation."""
        
        if not cls._llama4_breaker.can_execute():
            logger.warning("llama4_circuit_breaker_open")
            return cls._get_fallback_response("stress")
        
        system_prompt = cls.WELLNESS_SYSTEM_PROMPT
        if strict_mode:
            system_prompt += "\n\nSTRICT MODE: Absolutely no medical claims. Regenerate if uncertain."
        
        # Build conversation context
        messages = [{"role": "system", "content": system_prompt}]
        
        if context:
            messages.extend(context)
        
        messages.append({"role": "user", "content": message})
        
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.post(
                    "https://api.llama4.example/v1/chat/completions",
                    headers={
                        "Authorization": f"Bearer {settings.llama4_api_key}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "model": "llama-4-wellness",
                        "messages": messages,
                        "max_tokens": 500,
                        "temperature": 0.7,
                    }
                )
                
                if response.status_code != 200:
                    raise Exception(f"Llama 4 API error: {response.status_code}")
                
                data = response.json()
                ai_response = data["choices"][0]["message"]["content"]
                
                cls._llama4_breaker.record_success()
                logger.info("llama4_response_generated", length=len(ai_response))
                
                return ai_response
                
        except Exception as e:
            cls._llama4_breaker.record_failure()
            logger.error("llama4_call_failed", error=str(e))
            return cls._get_fallback_response("general")
    
    @classmethod
    async def _call_qwen35(
        cls,
        message: str,
        language: str,
        strict_mode: bool = False,
        context: Optional[List[str]] = None
    ) -> str:
        """Call Qwen 3.5 API for multilingual or complex reasoning."""
        
        if not cls._qwen35_breaker.can_execute():
            logger.warning("qwen35_circuit_breaker_open")
            return cls._get_fallback_response("stress")
        
        system_prompt = cls.WELLNESS_SYSTEM_PROMPT
        system_prompt += f"\n\nRespond in {language.upper()} language."
        
        if strict_mode:
            system_prompt += "\n\nSTRICT MODE: Absolutely no medical claims."
        
        messages = [{"role": "system", "content": system_prompt}]
        
        if context:
            messages.extend(context)
        
        messages.append({"role": "user", "content": message})
        
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.post(
                    "https://api.qwen35.example/v1/chat/completions",
                    headers={
                        "Authorization": f"Bearer {settings.qwen35_api_key}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "model": "qwen-3.5-turbo",
                        "messages": messages,
                        "max_tokens": 500,
                        "temperature": 0.7,
                    }
                )
                
                if response.status_code != 200:
                    raise Exception(f"Qwen 3.5 API error: {response.status_code}")
                
                data = response.json()
                ai_response = data["choices"][0]["message"]["content"]
                
                cls._qwen35_breaker.record_success()
                logger.info("qwen35_response_generated", language=language, length=len(ai_response))
                
                return ai_response
                
        except Exception as e:
            cls._qwen35_breaker.record_failure()
            logger.error("qwen35_call_failed", error=str(e))
            return cls._get_fallback_response("general")
    
    @classmethod
    async def analyze_visual(
        cls,
        frames: List[bytes],
        analysis_type: str,
        language: str = "en"
    ) -> Dict:
        """
        Analyze visual content using Qwen 3.5 VL.
        
        Args:
            frames: List of image frame bytes
            analysis_type: "meal" or "exercise"
            language: Response language
        
        Returns:
            Analysis results dict
        """
        if not cls._qwen35_breaker.can_execute():
            return cls._get_visual_fallback(analysis_type)
        
        # Build prompt based on analysis type
        if analysis_type == "meal":
            prompt = """Analyze this meal photo. Provide:
1. Estimated nutrition balance (protein, carbs, fats, fiber)
2. Wellness feedback (positive reinforcement)
3. Suggestions for improvement (wellness-focused)

Remember: Do NOT make medical claims about curing diseases."""
        else:  # exercise
            prompt = """Analyze this exercise form. Provide:
1. Form assessment (safe/needs adjustment)
2. Specific feedback on posture/alignment
3. Wellness encouragement

Remember: Do NOT claim this fixes injuries or medical conditions."""
        
        # Encode frames as base64
        import base64
        images = [base64.b64encode(frame).decode() for frame in frames]
        
        try:
            async with httpx.AsyncClient(timeout=60.0) as client:
                response = await client.post(
                    "https://api.qwen35.example/v1/chat/completions",
                    headers={
                        "Authorization": f"Bearer {settings.qwen35_api_key}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "model": "qwen-3.5-vl",
                        "messages": [{
                            "role": "user",
                            "content": [
                                {"type": "text", "text": prompt},
                                *[{"type": "image_url", "image_url": f"data:image/jpeg;base64,{img}"} for img in images]
                            ]
                        }],
                        "max_tokens": 800,
                    }
                )
                
                if response.status_code != 200:
                    raise Exception(f"Qwen 3.5 VL API error: {response.status_code}")
                
                data = response.json()
                analysis_text = data["choices"][0]["message"]["content"]
                
                cls._qwen35_breaker.record_success()
                logger.info("qwen35vl_analysis_complete", type=analysis_type)
                
                # Parse structured response
                return {
                    "analysis": analysis_text,
                    "safety_flag": False,
                    "analysis_type": analysis_type
                }
                
        except Exception as e:
            cls._qwen35_breaker.record_failure()
            logger.error("qwen35vl_analysis_failed", error=str(e))
            return cls._get_visual_fallback(analysis_type)
    
    @staticmethod
    def _get_fallback_response(category: str) -> str:
        """Return cached wellness tip when AI is unavailable."""
        fallbacks = {
            "stress": "When feeling stressed, try the 4-7-8 breathing technique: Inhale for 4 counts, hold for 7, exhale for 8. Repeat 3 times.",
            "sleep": "For better sleep, try maintaining a consistent bedtime routine and limiting screen time 1 hour before bed.",
            "nutrition": "A balanced plate includes: ½ vegetables, ¼ protein, ¼ whole grains. Small changes lead to lasting habits!",
            "movement": "Even 10 minutes of movement can boost your mood. Try a short walk or gentle stretching.",
            "general": "Take a moment to check in with yourself. How are you feeling right now? What does your body need?",
        }
        return fallbacks.get(category, fallbacks["general"])
    
    @staticmethod
    def _get_visual_fallback(analysis_type: str) -> Dict:
        """Return fallback for visual analysis."""
        if analysis_type == "meal":
            return {
                "analysis": "This looks like a thoughtful meal! Remember to include a variety of colors for different nutrients.",
                "safety_flag": False,
                "analysis_type": "meal"
            }
        else:
            return {
                "analysis": "Great job staying active! Listen to your body and rest when needed.",
                "safety_flag": False,
                "analysis_type": "exercise"
            }
