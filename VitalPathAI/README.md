# VitalPath AI - iOS/iPadOS Application

## 📱 Overview
VitalPath AI is a safety-first wellness coaching platform with beautiful Apple-style glass UI and smooth animations. Built with SwiftUI for iPhone and iPad.

## ✨ Features

### Glass UI Components
- Frosted glass cards with blur effects
- Animated gradient orb backgrounds
- Smooth pulse and ripple animations
- Message bubbles with gradients
- Crisis modals with full-screen override
- Video analysis overlay cards
- Habit streak rings with progress animation
- Skeleton loading states

### Core Modules
1. **Intelligent Wellness Chat** - Text & voice coaching with Llama 4
2. **Multi-Modal Video Analysis** - Meal/exercise analysis with Qwen 3.5 VL
3. **Habit & Session Tracking** - SwiftData persistence with streak logic
4. **Crisis Escalation & Safety** - Zero-tolerance policy with localized hotlines

### Safety Features
- Pre & post-processing safety validation
- Crisis keyword detection (suicide, self-harm, medical emergencies)
- Localized emergency numbers (US: 988, Thailand: 1323, Myanmar, Japan, etc.)
- Wellness-bound response generation
- Zero PHI logging (hashed only)

## 🏗️ Architecture

### Frontend (iOS - SwiftUI)
- **Pattern**: MVVM + Clean Architecture
- **State Management**: @Observable (iOS 17+)
- **Local DB**: SwiftData for offline-first experience
- **Networking**: Custom GraphQL client with retry policy & circuit breaker
- **Localization**: EN, MY, TH, ZH, JA, KO

### Backend (FastAPI + GraphQL)
- **API Gateway**: FastAPI handling HTTP/WS
- **GraphQL Layer**: Strawberry GraphQL
- **Task Queue**: Celery + Redis
- **Vector DB**: ChromaDB for semantic memory (RAG)
- **Auth**: Supabase Auth (JWT)

### AI Orchestration
- **Text Queries**: Llama 4 (low latency, high empathy)
- **Image/Video**: Qwen 3.5 VL (high visual accuracy)
- **Complex Reasoning**: Qwen 3.5 (large context window)

## 📁 Project Structure

```
VitalPathAI/
├── VitalPathAI.xcodeproj/          # Xcode project file
├── VitalPathAI/
│   ├── Sources/
│   │   ├── VitalPathAIApp.swift    # App entry point
│   │   ├── Views/
│   │   │   ├── ContentView.swift   # Home dashboard
│   │   │   ├── ChatView.swift      # Wellness chat interface
│   │   │   └── VideoAnalysisView.swift  # Video analysis screen
│   │   ├── ViewModels/
│   │   │   ├── HomeViewModel.swift
│   │   │   ├── ChatViewModel.swift
│   │   │   └── VideoAnalysisViewModel.swift
│   │   ├── Services/
│   │   │   ├── APIService.swift    # GraphQL client
│   │   │   └── SafetyValidator.swift  # Safety checks
│   │   ├── Components/
│   │   │   └── GlassUIComponents.swift  # Reusable glass UI
│   │   └── Models/
│   │       └── Models.swift        # Data models
│   ├── Assets.xcassets/            # App icons & colors
│   └── Preview Content/            # SwiftUI previews
├── backend/                        # FastAPI backend
│   ├── main.py                     # FastAPI app
│   ├── models.py                   # Pydantic models
│   ├── safety_validator.py         # Safety validation
│   └── services/                   # AI services
└── Package.swift                   # Swift Package Manager
```

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ / iPadOS 17.0+
- macOS Sonoma 14.0+ (for building)

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd VitalPathAI
```

2. **Open in Xcode**
```bash
open VitalPathAI/VitalPathAI.xcodeproj
```

3. **Configure Signing**
- Select your development team in Project Settings
- Ensure bundle identifier is unique

4. **Build & Run**
- Press `Cmd + R` to run on simulator or device
- Supports iPhone and iPad (universal app)

### Backend Setup

1. **Install dependencies**
```bash
cd backend
pip install -r requirements.txt
```

2. **Environment variables**
Create `.env` file:
```env
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_key
LLAMA_API_KEY=your_llama_api_key
QWEN_API_KEY=your_qwen_api_key
REDIS_URL=redis://localhost:6379
CHROMA_DB_PATH=./chroma_db
```

3. **Run backend**
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

4. **Run Celery worker**
```bash
celery -A tasks worker --loglevel=info
```

## 🛡️ Safety Boundaries

| Feature | ✅ ALLOWED (Wellness) | ❌ PROHIBITED (Medical) |
|---------|----------------------|------------------------|
| Diet | "This supports healthy energy levels." | "This cures diabetes." |
| Exercise | "This strengthens your legs." | "This fixes your ACL tear." |
| Mental Health | "Let's try a calming breathing exercise." | "I can treat your depression." |
| Symptoms | "Rest and hydration might help." | "You definitely have the flu." |
| Crisis | "Here is a helpline number immediately." | "I can talk you through this alone." |

**Mandatory Disclaimer**: Displayed on launch, chat screen, and video analysis:
> "VitalPath provides wellness guidance, not medical advice. Always consult a healthcare professional for medical concerns."

## 📊 Non-Functional Requirements

- **Latency**: 
  - Text Chat: < 2 seconds (P95)
  - Video Analysis: < 15 seconds (async)
- **Availability**: 99.9% uptime for chat
- **Privacy**: Zero-knowledge logs, PII stripped before AI
- **Scalability**: 1,000 concurrent users (MVP) → 50,000 (scale)

## 🌍 Localization

Supported languages:
- 🇺🇸 English (EN)
- 🇲🇲 Burmese (MY)
- 🇹🇭 Thai (TH)
- 🇨🇳 Chinese (ZH)
- 🇯🇵 Japanese (JA)
- 🇰🇷 Korean (KO)

## 📝 License

[Your License Here]

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

---

**Built with ❤️ for wellness, not medicine**
