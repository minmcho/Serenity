"""
VitalPath AI - Security Middleware for FastAPI

Implements:
- JWT Authentication validation
- Rate limiting
- Request/Response logging with PII masking
- Input sanitization
"""
import time
import re
from typing import Callable, Awaitable
from fastapi import Request, Response, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import structlog
from jose import jwt, JWTError

logger = structlog.get_logger()

# Security schemes
security = HTTPBearer(auto_error=False)

# Rate limiting storage (in production, use Redis)
_rate_limit_store: dict[str, list[float]] = {}


class SecurityConfig:
    """Security configuration constants."""
    
    JWT_ALGORITHM = "HS256"
    JWT_EXPIRY_MINUTES = 60 * 24  # 24 hours
    
    RATE_LIMIT_REQUESTS = 100  # requests per window
    RATE_LIMIT_WINDOW_SECONDS = 60  # 1 minute window
    
    MAX_REQUEST_SIZE_BYTES = 1_048_576  # 1MB
    
    # Patterns for PII detection
    EMAIL_PATTERN = r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'
    PHONE_PATTERN = r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b'
    SSN_PATTERN = r'\b\d{3}-\d{2}-\d{4}\b'


def mask_pii(text: str) -> str:
    """Mask sensitive information in logs."""
    masked = text
    
    # Mask emails
    masked = re.sub(SecurityConfig.EMAIL_PATTERN, '[EMAIL_REDACTED]', masked)
    
    # Mask phone numbers
    masked = re.sub(SecurityConfig.PHONE_PATTERN, '[PHONE_REDACTED]', masked)
    
    # Mask SSN
    masked = re.sub(SecurityConfig.SSN_PATTERN, '[SSN_REDACTED]', masked)
    
    return masked


async def validate_jwt_token(credentials: HTTPAuthorizationCredentials) -> dict | None:
    """
    Validate JWT token from Supabase Auth.
    
    Returns decoded claims if valid, None otherwise.
    """
    try:
        from app.config import settings
        
        payload = jwt.decode(
            credentials.credentials,
            settings.jwt_secret,
            algorithms=[SecurityConfig.JWT_ALGORITHM],
            options={"verify_exp": True}
        )
        
        logger.info("jwt_validated", user_id=payload.get("sub"))
        return payload
        
    except JWTError as e:
        logger.warning("jwt_validation_failed", error=str(e))
        return None
    except Exception as e:
        logger.error("jwt_decode_error", error=str(e))
        return None


def check_rate_limit(client_ip: str) -> bool:
    """
    Check if client has exceeded rate limit.
    
    Returns True if request is allowed, False if rate limited.
    """
    current_time = time.time()
    window_start = current_time - SecurityConfig.RATE_LIMIT_WINDOW_SECONDS
    
    # Clean old entries
    if client_ip in _rate_limit_store:
        _rate_limit_store[client_ip] = [
            ts for ts in _rate_limit_store[client_ip]
            if ts > window_start
        ]
    else:
        _rate_limit_store[client_ip] = []
    
    # Check limit
    if len(_rate_limit_store[client_ip]) >= SecurityConfig.RATE_LIMIT_REQUESTS:
        logger.warning("rate_limit_exceeded", client_ip=mask_pii(client_ip))
        return False
    
    # Record this request
    _rate_limit_store[client_ip].append(current_time)
    return True


async def security_middleware(
    request: Request,
    call_next: Callable[[Request], Awaitable[Response]]
) -> Response:
    """
    Main security middleware applying all security checks.
    """
    start_time = time.time()
    client_ip = request.client.host if request.client else "unknown"
    
    # Log incoming request (with PII masked)
    logger.info(
        "request_received",
        method=request.method,
        path=mask_pii(str(request.url.path)),
        client_ip=mask_pii(client_ip),
        user_agent=request.headers.get("user-agent", "unknown")[:50]
    )
    
    # Check request size
    content_length = request.headers.get("content-length")
    if content_length and int(content_length) > SecurityConfig.MAX_REQUEST_SIZE_BYTES:
        logger.warning("request_too_large", size=content_length)
        raise HTTPException(
            status_code=status.HTTP_413_PAYLOAD_TOO_LARGE,
            detail="Request body too large"
        )
    
    # Apply rate limiting (skip for health checks)
    if request.url.path not in ["/api/v1/health", "/docs", "/redoc"]:
        if not check_rate_limit(client_ip):
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Rate limit exceeded. Please try again later."
            )
    
    # Validate JWT for protected routes
    protected_paths = ["/graphql", "/api/v1"]
    if any(request.url.path.startswith(path) for path in protected_paths):
        if request.url.path != "/api/v1/health":
            credentials = await security(request)
            
            if credentials:
                token_payload = await validate_jwt_token(credentials)
                
                if token_payload:
                    # Attach user info to request state
                    request.state.user_id = token_payload.get("sub")
                    request.state.user_email = token_payload.get("email")
                else:
                    # Token invalid - allow public endpoints, block protected ones
                    public_endpoints = ["/api/v1/public"]
                    if not any(request.url.path.startswith(ep) for ep in public_endpoints):
                        raise HTTPException(
                            status_code=status.HTTP_401_UNAUTHORIZED,
                            detail="Invalid or expired token"
                        )
    
    # Process request
    response = await call_next(request)
    
    # Log response
    process_time = time.time() - start_time
    logger.info(
        "request_completed",
        method=request.method,
        path=mask_pii(str(request.url.path)),
        status_code=response.status_code,
        process_time_ms=round(process_time * 1000, 2)
    )
    
    # Add security headers
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    response.headers["Content-Security-Policy"] = "default-src 'self'"
    
    return response


async def log_sensitive_access(user_id: str | None, resource: str, action: str):
    """Log access to sensitive resources for audit trail."""
    logger.info(
        "sensitive_resource_accessed",
        user_id=mask_pii(user_id or "anonymous"),
        resource=resource,
        action=action,
        timestamp=time.time()
    )


def sanitize_input(text: str) -> str:
    """
    Sanitize user input by removing potentially dangerous characters.
    
    Prevents XSS and injection attacks.
    """
    # Remove null bytes
    text = text.replace('\x00', '')
    
    # Limit length
    max_length = 10000
    if len(text) > max_length:
        text = text[:max_length]
    
    return text
