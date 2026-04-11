"""
VitalPath AI - Safety Validator for Crisis Detection & Wellness Boundaries

This module implements zero-tolerance safety checks for:
- Self-harm and crisis keywords
- Medical emergency terms  
- Prohibited medical claims (diagnosis, treatment, prescription)
"""
import re
import hashlib
from typing import Dict, List, Optional
from enum import Enum


class SafetyLevel(Enum):
    SAFE = "safe"
    WARNING = "warning"
    BLOCKED = "blocked"
    CRISIS = "crisis"


class SafetyValidator:
    """
    Safety validation engine for wellness coaching platform.
    
    Implements pre-processing (input) and post-processing (output) safety checks
    to ensure all AI interactions remain within wellness boundaries.
    """
    
    # Crisis keywords requiring immediate intervention
    CRISIS_KEYWORDS = [
        "suicide",
        "kill myself",
        "end my life",
        "hurt myself",
        "self harm",
        "overdose",
        "want to die",
        "no reason to live",
        "better off dead",
    ]
    
    # Medical emergency terms
    MEDICAL_EMERGENCY_KEYWORDS = [
        "chest pain",
        "can't breathe",
        "heart attack",
        "stroke symptoms",
        "severe bleeding",
        "unconscious",
        "seizure",
        "poisoning",
    ]
    
    # Prohibited medical claims (wellness boundary)
    PROHIBITED_MEDICAL_CLAIMS = [
        "cure",
        "diagnose",
        "prescribe",
        "treatment for",
        "medication for",
        "surgery for",
        "clinical trial",
        "dosage",
        "side effects of",
        "drug interaction",
    ]
    
    # Wellness-appropriate alternatives
    WELLNESS_ALTERNATIVES = {
        "cure": "support healthy",
        "diagnose": "help you understand",
        "prescribe": "suggest trying",
        "treatment": "wellness approach",
        "medicine": "natural remedy",
        "patient": "individual",
    }
    
    _initialized = False
    
    @classmethod
    def initialize(cls):
        """Initialize the safety validator."""
        cls._initialized = True
        print("SafetyValidator initialized")
    
    @classmethod
    def validate_input(cls, text: str) -> Dict:
        """
        Validate user input before sending to AI.
        
        Returns:
            Dict with keys: safe, blocked, crisis_detected, keywords_found
        """
        text_lower = text.lower()
        
        # Check for crisis keywords
        crisis_found = []
        for keyword in cls.CRISIS_KEYWORDS:
            if keyword in text_lower:
                crisis_found.append(keyword)
        
        if crisis_found:
            return {
                "safe": False,
                "blocked": False,
                "crisis_detected": True,
                "keywords_found": crisis_found,
                "level": SafetyLevel.CRISIS.value,
                "message": "Crisis keywords detected - immediate escalation required"
            }
        
        # Check for medical emergencies
        emergency_found = []
        for keyword in cls.MEDICAL_EMERGENCY_KEYWORDS:
            if keyword in text_lower:
                emergency_found.append(keyword)
        
        if emergency_found:
            return {
                "safe": False,
                "blocked": False,
                "crisis_detected": True,
                "keywords_found": emergency_found,
                "level": SafetyLevel.CRISIS.value,
                "message": "Medical emergency detected - advise professional care"
            }
        
        return {
            "safe": True,
            "blocked": False,
            "crisis_detected": False,
            "keywords_found": [],
            "level": SafetyLevel.SAFE.value,
            "message": "Input is safe"
        }
    
    @classmethod
    def validate_output(cls, text: str) -> Dict:
        """
        Validate AI output before displaying to user.
        
        Blocks any medical claims, diagnoses, or treatment advice.
        
        Returns:
            Dict with keys: safe, blocked, prohibited_claims, suggestions
        """
        text_lower = text.lower()
        
        # Check for prohibited medical claims
        prohibited_found = []
        for claim in cls.PROHIBITED_MEDICAL_CLAIMS:
            # Use word boundaries to avoid false positives
            pattern = r'\b' + re.escape(claim) + r'\b'
            if re.search(pattern, text_lower):
                prohibited_found.append(claim)
        
        if prohibited_found:
            return {
                "safe": False,
                "blocked": True,
                "prohibited_claims": prohibited_found,
                "level": SafetyLevel.BLOCKED.value,
                "message": "Medical claims detected - response blocked",
                "suggestions": cls._get_wellness_alternatives(prohibited_found)
            }
        
        # Check for implicit diagnosis patterns
        diagnosis_patterns = [
            r"you have \w+",
            r"you're suffering from",
            r"this is clearly \w+",
            r"definitely \w+",
            r"your condition is",
        ]
        
        for pattern in diagnosis_patterns:
            if re.search(pattern, text_lower):
                return {
                    "safe": False,
                    "blocked": True,
                    "prohibited_claims": ["implicit_diagnosis"],
                    "level": SafetyLevel.BLOCKED.value,
                    "message": "Implicit diagnosis detected - response blocked"
                }
        
        return {
            "safe": True,
            "blocked": False,
            "prohibited_claims": [],
            "level": SafetyLevel.SAFE.value,
            "message": "Output is safe"
        }
    
    @classmethod
    def sanitize_for_ai(cls, text: str) -> str:
        """
        Sanitize text by replacing prohibited terms with wellness alternatives.
        
        Use this when regenerating responses in strict wellness mode.
        """
        sanitized = text
        for prohibited, alternative in cls.WELLNESS_ALTERNATIVES.items():
            pattern = r'\b' + re.escape(prohibited) + r'\b'
            sanitized = re.sub(pattern, alternative, sanitized, flags=re.IGNORECASE)
        return sanitized
    
    @classmethod
    def _get_wellness_alternatives(cls, prohibited_claims: List[str]) -> Dict[str, str]:
        """Get wellness-appropriate alternatives for prohibited claims."""
        suggestions = {}
        for claim in prohibited_claims:
            if claim in cls.WELLNESS_ALTERNATIVES:
                suggestions[claim] = cls.WELLNESS_ALTERNATIVES[claim]
        return suggestions
    
    @classmethod
    def hash_sensitive_data(cls, data: str) -> str:
        """
        Hash sensitive data for audit logging without storing PHI.
        
        Uses SHA-256 with salt for one-way hashing.
        """
        import os
        salt = os.getenv("HASH_SALT", "vitalpath_default_salt_change_in_production")
        hashed = hashlib.sha256((data + salt).encode()).hexdigest()
        return hashed
    
    @classmethod
    def get_crisis_helpline(cls, region: str) -> Dict[str, str]:
        """Get localized crisis helpline information."""
        helplines = {
            "US": {
                "number": "988",
                "name": "Suicide & Crisis Lifeline",
                "available": "24/7"
            },
            "TH": {
                "number": "1323",
                "name": "Thai Mental Health Hotline",
                "available": "24/7"
            },
            "MM": {
                "number": "+95-1-234567",
                "name": "Myanmar Mental Health Support",
                "available": "Mon-Fri 9AM-5PM"
            },
            "JP": {
                "number": "03-5286-1165",
                "name": "Inochi-no-Denwa",
                "available": "24/7"
            },
            "KR": {
                "number": "109",
                "name": "Korea Suicide Prevention Center",
                "available": "24/7"
            },
            "MY": {
                "number": "+60-3-7956-8145",
                "name": "Befrienders Kuala Lumpur",
                "available": "24/7"
            },
        }
        
        return helplines.get(region.upper(), helplines["US"])


# Convenience functions
def validate_input(text: str) -> Dict:
    return SafetyValidator.validate_input(text)


def validate_output(text: str) -> Dict:
    return SafetyValidator.validate_output(text)


def hash_sensitive(text: str) -> str:
    return SafetyValidator.hash_sensitive_data(text)
