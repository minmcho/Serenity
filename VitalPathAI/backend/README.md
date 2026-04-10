# VitalPath AI Backend

FastAPI + GraphQL backend with Llama 4 and Qwen 3.5 VL integration for wellness coaching.

## Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI application entry point
│   ├── config.py            # Configuration settings
│   ├── api/
│   │   ├── __init__.py
│   │   ├── graphql.py       # Strawberry GraphQL schema
│   │   └── routes.py        # REST API routes
│   ├── core/
│   │   ├── __init__.py
│   │   ├── security.py      # JWT & auth utilities
│   │   └── safety.py        # Safety validator (crisis detection)
│   ├── models/
│   │   ├── __init__.py
│   │   ├── user.py          # User & WellnessProfile models
│   │   ├── session.py       # WellnessSession models
│   │   └── wearable.py      # WearableConnection models
│   ├── services/
│   │   ├── __init__.py
│   │   ├── ai_orchestrator.py  # Llama 4 & Qwen 3.5 routing
│   │   ├── vector_store.py     # ChromaDB integration
│   │   └── healthkit.py        # Apple Health data sync
│   └── tasks/
│       ├── __init__.py
│       ├── celery_app.py    # Celery configuration
│       └── video_analysis.py # Qwen 3.5 VL video processing
├── tests/
│   ├── __init__.py
│   └── test_safety.py
├── requirements.txt
├── .env.example
└── README.md
```

## Quick Start

### Prerequisites
- Python 3.10+
- Redis server
- Supabase project
- ChromaDB instance
- Llama 4 API key
- Qwen 3.5 API key

### Installation

```bash
cd backend
python -m venv venv
source venv/bin/activate  # or `venv\Scripts\activate` on Windows
pip install -r requirements.txt
```

### Environment Setup

Copy `.env.example` to `.env` and fill in your credentials:

```bash
cp .env.example .env
```

Required environment variables:
- `SUPABASE_URL`
- `SUPABASE_KEY`
- `REDIS_URL`
- `CHROMADB_URL`
- `LLAMA4_API_KEY`
- `QWEN35_API_KEY`
- `JWT_SECRET`

### Running the Services

1. **Start Redis** (required for Celery):
```bash
redis-server
```

2. **Start Celery Worker** (for video analysis & AI tasks):
```bash
celery -A app.tasks.celery_app worker --loglevel=info
```

3. **Start FastAPI Server**:
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

4. **Access GraphQL Playground**:
Open http://localhost:8000/graphql

## API Endpoints

### GraphQL Schema

```graphql
type Query {
  userProfile: WellnessProfile
  wellnessSessions(limit: Int): [WellnessSession]
  wearableData: WearableConnection
}

type Mutation {
  sendMessage(message: String!): ChatResponse
  uploadVideo(videoUrl: String!, analysisType: String!): VideoAnalysisTask
  logSession(sessionInput: SessionInput!): WellnessSession
  updateGoals(goals: [String!]!): WellnessProfile
}

type Subscription {
  videoAnalysisResult(taskId: ID!): VideoAnalysisResult
  chatStream(messageId: ID!): ChatMessage
}
```

### REST Routes

- `POST /api/v1/crisis/escalate` - Manual crisis escalation
- `GET /api/v1/health` - Health check endpoint
- `POST /api/v1/webhooks/supabase` - Supabase webhook handler

## Safety Features

### Crisis Detection

The `SafetyValidator` scans all inputs/outputs for:
- Self-harm keywords ("suicide", "hurt myself")
- Medical emergency terms ("chest pain", "can't breathe")
- Prohibited medical claims ("cure", "diagnose", "prescribe")

If detected:
1. AI generation is immediately stopped
2. Crisis modal is triggered on frontend
3. Localized helpline numbers are displayed
4. Input is hashed (no PHI stored)

### Wellness Boundaries

All AI prompts include system instructions:
> "You are a wellness coach, NOT a doctor. Never diagnose, treat, or prescribe. Provide supportive lifestyle guidance only."

## AI Orchestration

### Model Router

| Input Type | Model | Purpose |
|------------|-------|---------|
| Text Chat | Llama 4 | Low latency, empathetic responses |
| Image/Video | Qwen 3.5 VL | Visual analysis (meals, exercise form) |
| Complex Reasoning | Qwen 3.5 | Multilingual, large context queries |

### Vector Memory (RAG)

User preferences and history are stored in ChromaDB:
- Collection: `user_wellness_context`
- Index: HNSW for fast similarity search
- Retrieved before each AI response for personalization

## Video Analysis Flow

1. User records 30s video → Uploads to Supabase Storage
2. FastAPI receives upload → Creates Celery task
3. Celery worker:
   - Extracts key frames from video
   - Sends frames to Qwen 3.5 VL API
   - Parses JSON response
   - Validates safety boundaries
4. Result pushed via WebSocket to frontend
5. Overlay cards displayed on video player

## Testing

### Run All Tests
```bash
pytest tests/ -v
```

### Red Team Testing
Attempt to force medical advice:
```bash
python tests/red_team_test.py
```

### Load Testing
```bash
locust -f tests/load_test.py --host=http://localhost:8000
```

## Deployment

### Docker

```bash
docker build -t vitalpath-backend .
docker run -p 8000:8000 --env-file .env vitalpath-backend
```

### Cloud Run (Google Cloud)

```bash
gcloud run deploy vitalpath-backend \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

### Fly.io

```bash
flyctl launch
flyctl deploy
```

## Monitoring

- **Health Checks**: `/api/v1/health`
- **Metrics**: Prometheus endpoint at `/metrics`
- **Logging**: Structured JSON logs to stdout
- **Alerts**: Configured for circuit breaker trips & safety violations

## License

Proprietary - VitalPath AI © 2025
