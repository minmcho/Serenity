"""
VitalPath AI - Safety Validator Tests

Run with: pytest tests/test_safety.py -v
"""
import pytest
from app.core.safety import SafetyValidator


class TestSafetyValidator:
    """Test suite for SafetyValidator."""
    
    def test_initialize(self):
        """Test validator initialization."""
        SafetyValidator.initialize()
        assert SafetyValidator._initialized is True
    
    def test_validate_input_safe(self):
        """Test safe input passes validation."""
        result = SafetyValidator.validate_input("I feel stressed about work")
        
        assert result["safe"] is True
        assert result["blocked"] is False
        assert result["crisis_detected"] is False
        assert len(result["keywords_found"]) == 0
    
    def test_validate_input_crisis_suicide(self):
        """Test crisis keyword detection - suicide."""
        result = SafetyValidator.validate_input("I want to kill myself")
        
        assert result["safe"] is False
        assert result["crisis_detected"] is True
        assert "kill myself" in result["keywords_found"]
    
    def test_validate_input_crisis_self_harm(self):
        """Test crisis keyword detection - self harm."""
        result = SafetyValidator.validate_input("I want to hurt myself")
        
        assert result["crisis_detected"] is True
        assert "hurt myself" in result["keywords_found"]
    
    def test_validate_input_medical_emergency(self):
        """Test medical emergency detection."""
        result = SafetyValidator.validate_input("I have chest pain and can't breathe")
        
        assert result["crisis_detected"] is True
        assert any(k in result["keywords_found"] for k in ["chest pain", "can't breathe"])
    
    def test_validate_output_safe(self):
        """Test safe output passes validation."""
        result = SafetyValidator.validate_output(
            "This meal looks balanced with good protein and fiber!"
        )
        
        assert result["safe"] is True
        assert result["blocked"] is False
    
    def test_validate_output_blocked_cure(self):
        """Test output blocked for medical cure claim."""
        result = SafetyValidator.validate_output(
            "This will cure your diabetes"
        )
        
        assert result["safe"] is False
        assert result["blocked"] is True
        assert "cure" in result["prohibited_claims"]
    
    def test_validate_output_blocked_diagnose(self):
        """Test output blocked for diagnosis claim."""
        result = SafetyValidator.validate_output(
            "You definitely have the flu based on these symptoms"
        )
        
        assert result["blocked"] is True
    
    def test_validate_output_blocked_prescribe(self):
        """Test output blocked for prescription claim."""
        result = SafetyValidator.validate_output(
            "I prescribe you to take this supplement daily"
        )
        
        assert result["blocked"] is True
        assert "prescribe" in result["prohibited_claims"]
    
    def test_sanitize_for_ai(self):
        """Test text sanitization replaces prohibited terms."""
        text = "This medicine can cure your condition"
        sanitized = SafetyValidator.sanitize_for_ai(text)
        
        assert "cure" not in sanitized.lower() or "support healthy" in sanitized.lower()
    
    def test_hash_sensitive_data(self):
        """Test sensitive data hashing."""
        data = "user123_sensitive_info"
        hashed1 = SafetyValidator.hash_sensitive_data(data)
        hashed2 = SafetyValidator.hash_sensitive_data(data)
        
        # Same input should produce same hash
        assert hashed1 == hashed2
        
        # Hash should be different from original
        assert hashed1 != data
        
        # Hash should be 64 characters (SHA-256 hex)
        assert len(hashed1) == 64
    
    def test_get_crisis_helpline_us(self):
        """Test US crisis helpline retrieval."""
        helpline = SafetyValidator.get_crisis_helpline("US")
        
        assert helpline["number"] == "988"
        assert helpline["name"] == "Suicide & Crisis Lifeline"
    
    def test_get_crisis_helpline_thailand(self):
        """Test Thailand crisis helpline retrieval."""
        helpline = SafetyValidator.get_crisis_helpline("TH")
        
        assert helpline["number"] == "1323"
        assert helpline["name"] == "Thai Mental Health Hotline"
    
    def test_get_crisis_helpline_default(self):
        """Test default helpline for unknown region."""
        helpline = SafetyValidator.get_crisis_helpline("UNKNOWN")
        
        # Should default to US
        assert helpline["number"] == "988"
    
    def test_wellness_alternatives_exist(self):
        """Test wellness alternatives dictionary has entries."""
        assert len(SafetyValidator.WELLNESS_ALTERNATIVES) > 0
        assert "cure" in SafetyValidator.WELLNESS_ALTERNATIVES
        assert "diagnose" in SafetyValidator.WELLNESS_ALTERNATIVES


class TestConvenienceFunctions:
    """Test module-level convenience functions."""
    
    def test_validate_input_function(self):
        """Test validate_input convenience function."""
        from app.core.safety import validate_input
        
        result = validate_input("I'm feeling anxious")
        assert isinstance(result, dict)
    
    def test_validate_output_function(self):
        """Test validate_output convenience function."""
        from app.core.safety import validate_output
        
        result = validate_output("This supports healthy energy levels")
        assert isinstance(result, dict)
    
    def test_hash_sensitive_function(self):
        """Test hash_sensitive convenience function."""
        from app.core.safety import hash_sensitive
        
        hashed = hash_sensitive("test_data")
        assert len(hashed) == 64


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
