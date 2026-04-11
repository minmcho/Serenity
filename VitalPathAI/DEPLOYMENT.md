# VitalPath AI - Production Deployment Guide

## 🏗️ System Architecture Overview

VitalPath AI is a safety-first wellness coaching platform built with:

### Frontend (iOS)
- **SwiftUI** with iOS 17+ @Observable pattern
- **SwiftData** for offline-first local persistence
- **HealthKit** integration for wearable data
- **Apple Glass UI** with rich animations

### Backend
- **FastAPI** with GraphQL (Strawberry)
- **Celery + Redis** for async task processing
- **ChromaDB** for vector-based semantic memory
- **Supabase** for Auth, PostgreSQL, and Storage

### AI Orchestration
- **Llama 4**: Text chat, empathetic responses
- **Qwen 3.5**: Multilingual support (MY, TH, ZH, JA, KO)
- **Qwen 3.5 VL**: Visual analysis (meals, exercise)

---

## 🚀 Production Deployment

### Prerequisites

1. **Cloud Provider**: Google Cloud Run, AWS ECS, or Fly.io
2. **Database**: Supabase project (free tier available)
3. **Redis**: Redis Cloud or self-hosted
4. **AI APIs**: Llama 4 and Qwen 3.5 API keys
5. **Domain**: Custom domain with SSL certificate

### Backend Deployment

#### 1. Environment Variables

Create `.env` file in production:

```bash
# Application
ENVIRONMENT=production
SECRET_KEY=your-super-secret-key-change-in-production
HASH_SALT=your-hash-salt-change-in-production

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_KEY=your-service-key

# JWT Auth
JWT_SECRET=your-jwt-secret-from-supabase

# AI APIs
LLAMA4_API_KEY=your-llama4-api-key
QWEN35_API_KEY=your-qwen35-api-key

# Redis
REDIS_URL=redis://your-redis-host:6379/0

# CORS
CORS_ORIGINS=https://vitalpath.ai,https://app.vitalpath.ai

# Rate Limiting
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW_SECONDS=60

# Crisis Helplines
CRISIS_US=988
CRISIS_TH=1323
CRISIS_MM=+95-1-234567
CRISIS_JP=03-5286-1165
CRISIS_KR=109
CRISIS_MY=+60-3-7956-8145
```

#### 2. Docker Build & Deploy

```bash
# Build Docker image
docker build -t vitalpath-backend:latest ./backend

# Tag for registry
docker tag vitalpath-backend:latest gcr.io/your-project/vitalpath-backend:latest

# Push to registry
docker push gcr.io/your-project/vitalpath-backend:latest

# Deploy to Cloud Run
gcloud run deploy vitalpath-backend \
  --image gcr.io/your-project/vitalpath-backend:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars ENV_FILE=.env \
  --memory 2Gi \
  --cpu 2 \
  --min-instances 1 \
  --max-instances 100
```

#### 3. Celery Workers

```bash
# Deploy Celery worker service
gcloud run deploy vitalpath-worker \
  --image gcr.io/your-project/vitalpath-backend:latest \
  --command celery \
  --args "-A app.tasks.celery_app worker --loglevel=info" \
  --platform managed \
  --region us-central1 \
  --set-env-vars ENV_FILE=.env \
  --min-instances 2 \
  --max-instances 20
```

#### 4. Database Setup

Run database migrations:

```sql
-- Execute database_schema.sql in Supabase SQL Editor
-- Enable Row Level Security (RLS) on all tables
ALTER TABLE wellness_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE wellness_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE wearable_connections ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view own profile"
ON wellness_profiles FOR SELECT
USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own profile"
ON wellness_profiles FOR INSERT
WITH CHECK (auth.uid()::text = user_id);
```

### iOS App Deployment

#### 1. Xcode Configuration

1. Open `VitalPathAI.xcodeproj` in Xcode 15+
2. Configure signing team in Project Settings
3. Add required capabilities:
   - HealthKit
   - Background Modes (for health data sync)
   - Camera Usage
   - Microphone Usage (for voice input)

#### 2. Info.plist Entries

```xml
<key>NSHealthShareUsageDescription</key>
<string>VitalPath AI uses your health data to provide personalized wellness insights.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>VitalPath AI saves your wellness sessions to track your progress.</string>

<key>NSCameraUsageDescription</key>
<string>VitalPath AI uses the camera to analyze your meals and exercise form.</string>

<key>NSMicrophoneUsageDescription</key>
<string>VitalPath AI uses the microphone for voice-based wellness coaching.</string>
```

#### 3. App Store Connect Setup

1. Create new app in App Store Connect
2. Configure App Privacy Details:
   - Health & Fitness data collected
   - Contact Info (email for support)
   - User Content (wellness sessions)
3. Submit for review with note about wellness (not medical) purpose

#### 4. TestFlight Distribution

```bash
# Archive app in Xcode
# Product → Archive
# Distribute → TestFlight
# Add internal/external testers
```

---

## 🔒 Security Best Practices

### Implemented Security Measures

1. **JWT Authentication**: All API requests require valid Supabase JWT
2. **Rate Limiting**: 100 requests/minute per IP
3. **PII Masking**: All logs automatically redact emails, phones, SSNs
4. **Input Sanitization**: XSS and injection attack prevention
5. **Security Headers**: HSTS, CSP, X-Frame-Options, etc.
6. **Circuit Breakers**: Prevent cascade failures in AI services
7. **Zero-Knowledge Crisis Logging**: Crisis events hashed, no PHI stored

### Additional Recommendations

1. **Enable WAF**: Use Cloudflare or AWS WAF for DDoS protection
2. **Secrets Management**: Use AWS Secrets Manager or GCP Secret Manager
3. **Audit Logging**: Forward logs to SIEM (Splunk, Datadog)
4. **Penetration Testing**: Quarterly security audits
5. **Dependency Scanning**: Use Snyk or Dependabot

---

## 📊 Monitoring & Observability

### Metrics to Track

```python
# Key performance indicators
- API latency (P95 < 2s for chat, < 15s for video)
- Error rate (< 0.1%)
- Circuit breaker trips
- Crisis detection count
- Active users (DAU/MAU)
- Session completion rate
```

### Recommended Tools

- **Application Monitoring**: New Relic, Datadog, or Sentry
- **Log Aggregation**: ELK Stack or Google Cloud Logging
- **Uptime Monitoring**: UptimeRobot or Pingdom
- **Error Tracking**: Sentry with release tracking

### Alerting Rules

```yaml
alerts:
  - name: HighErrorRate
    condition: error_rate > 1%
    severity: critical
    
  - name: HighLatency
    condition: p95_latency > 5s
    severity: warning
    
  - name: CircuitBreakerOpen
    condition: circuit_breaker_status == open
    severity: critical
    
  - name: CrisisSpike
    condition: crisis_events > 10/hour
    severity: critical
```

---

## 🌍 Localization

### Supported Languages

- 🇺🇸 English (en)
- 🇲🇲 Myanmar (my)
- 🇹🇭 Thai (th)
- 🇨🇳 Chinese (zh)
- 🇯🇵 Japanese (ja)
- 🇰🇷 Korean (ko)

### Adding New Languages

1. Create `.lproj` folder in iOS app
2. Add `Localizable.strings` file
3. Update `LocalizationManager.swift` with translations
4. Add crisis helpline info for new region

---

## 🧪 Testing Strategy

### Automated Tests

```bash
# Backend tests
cd backend
pytest tests/ -v --cov=app

# Run security tests
pytest tests/test_security.py -v

# Load testing with Locust
locust -f tests/load_test.py --host=http://localhost:8000
```

### Manual Testing Checklist

- [ ] Crisis keyword detection works
- [ ] Medical claims are blocked
- [ ] All 6 languages render correctly
- [ ] HealthKit sync works on device
- [ ] Video analysis completes in < 15s
- [ ] Offline mode functions properly
- [ ] Streak logic handles timezone changes

### Red Teaming

Attempt to bypass safety systems:
- Try to get AI to diagnose conditions
- Test prompt injection attacks
- Verify crisis escalation works
- Check PII leakage in logs

---

## 📈 Scaling Strategy

### Phase 1: MVP (1,000 concurrent users)

- Single Cloud Run instance (min 1, max 10)
- 2 Celery workers
- Supabase free tier
- Basic monitoring

### Phase 2: Growth (10,000 concurrent users)

- Auto-scaling Cloud Run (min 5, max 50)
- 10 Celery workers with queue-based scaling
- Supabase Pro tier
- Redis cluster
- CDN for static assets

### Phase 3: Scale (50,000+ concurrent users)

- Multi-region deployment
- Database read replicas
- Dedicated vector DB cluster
- Advanced caching layer
- Global load balancing

---

## 🆘 Crisis Response Protocol

### Automated Detection

1. Input scanned for crisis keywords
2. AI generation halted immediately
3. Full-screen modal displayed with helpline
4. Event logged (hashed, no PHI)

### Human Review (Future)

1. Flagged sessions queued for admin review
2. Wellness coaches can follow up (with consent)
3. Escalation path to emergency services if needed

### Compliance

- **HIPAA**: Not applicable (wellness, not medical)
- **GDPR**: Data export/deletion endpoints provided
- **CCPA**: Privacy policy discloses data usage
- **COPPA**: Age gate (18+ only)

---

## 📞 Support & Maintenance

### Team Roles

- **On-call Engineer**: Rotating weekly, responds to PagerDuty
- **Wellness Safety Officer**: Reviews flagged content
- **DevOps Lead**: Manages infrastructure updates
- **Product Owner**: Prioritizes feature requests

### Release Schedule

- **Minor Updates**: Bi-weekly (features, improvements)
- **Patch Releases**: As needed (bug fixes, security)
- **Major Versions**: Quarterly (breaking changes)

### Documentation

- Keep README updated
- Maintain API documentation (/docs endpoint)
- Document all safety decisions
- Version control for prompts

---

## ✅ Launch Checklist

### Pre-Launch

- [ ] All security headers configured
- [ ] Rate limiting tested
- [ ] Crisis helplines verified for all regions
- [ ] Legal review of disclaimers
- [ ] App Store guidelines compliance
- [ ] Load testing completed
- [ ] Backup/recovery tested

### Day 1

- [ ] Monitor error rates closely
- [ ] Have on-call engineer ready
- [ ] Prepare rollback plan
- [ ] Social media announcement scheduled

### Post-Launch (Week 1)

- [ ] Daily standups to review metrics
- [ ] Collect user feedback
- [ ] Fix critical bugs within 24h
- [ ] Plan iteration based on usage patterns

---

## 📄 License & Compliance

**Disclaimer**: VitalPath AI provides wellness guidance only and does not offer medical advice, diagnosis, or treatment. Always consult qualified healthcare providers for medical concerns.

© 2025 VitalPath AI. All rights reserved.
