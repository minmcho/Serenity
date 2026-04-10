"""
VitalPath AI - Configuration Settings
"""
from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    """Application configuration."""
    
    # Supabase
    supabase_url: str
    supabase_key: str
    
    # Redis
    redis_url: str = "redis://localhost:6379/0"
    
    # ChromaDB
    chromadb_url: str = "http://localhost:8000"
    
    # AI APIs
    llama4_api_key: str
    qwen35_api_key: str
    
    # JWT
    jwt_secret: str
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    
    # Security
    cors_origins: List[str] = ["http://localhost:3000"]
    environment: str = "development"
    
    # Crisis Helplines
    crisis_us: str = "988"
    crisis_th: str = "1323"
    crisis_mm: str = "+95-1-234567"
    crisis_jp: str = "03-5286-1165"
    
    # Circuit Breaker
    circuit_breaker_threshold: int = 5
    circuit_breaker_timeout: int = 60
    
    class Config:
        env_file = ".env"
        case_sensitive = False


settings = Settings()
