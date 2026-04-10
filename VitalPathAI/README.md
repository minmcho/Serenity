# VitalPath AI

## Safety-First Wellness Coaching Platform

**Core Philosophy:** "Wellness, Not Medicine"

VitalPath AI is a comprehensive iOS/iPadOS application that leverages multi-modal AI (Llama 4 for text, Qwen 3.5 VL for video) to provide personalized lifestyle guidance while maintaining strict safety boundaries.

## Features

### 🎨 Apple-Style Rich Glass UI
- Frosted glass effects with `.ultraThinMaterial` and `.thinMaterial`
- Animated gradient orbs for dynamic backgrounds
- Smooth spring animations throughout
- Hover effects and scale transformations
- Pulse button animations
- Skeleton loading states

### 💬 Intelligent Wellness Chat
- Context-aware memory using user preferences
- Multi-agent orchestration (Llama 4 + Qwen 3.5)
- Real-time safety interception (pre & post-processing)
- Crisis detection with immediate escalation
- Typing indicators and message bubbles
- Voice input support

### 📹 Multi-Modal Video Analysis
- Record or upload meals/exercises (up to 30s)
- Qwen 3.5 VL powered visual reasoning
- Real-time overlay cards on video player
- Wellness-bound feedback only
- Confidence scoring

### 📊 Habit & Session Tracking
- SwiftData local persistence (offline-first)
- Dynamic goal setting based on past performance
- Apple HealthKit integration (steps, heart rate)
- Streak logic with "Freeze Streak" feature
- Animated progress rings

### 🛡️ Crisis Escalation & Safety
- Zero-tolerance policy for self-harm keywords
- Hard interruption with full-screen crisis modal
- Localized helplines (US: 988, Thailand: 1323, etc.)
- Hashed logging (no PHI stored)
- Safety banners on all screens

## Technical Architecture

### Frontend (iOS - SwiftUI)
- **Architecture:** MVVM + Clean Architecture
- **State Management:** `@Observable` (iOS 17+)
- **Local DB:** SwiftData
- **Networking:** Custom GraphQL client with retry policy & circuit breaker
- **Localization:** EN, MY, TH, ZH, JA, KO

### Backend (FastAPI + GraphQL)
- **API Gateway:** FastAPI (HTTP/WS)
- **GraphQL Layer:** Strawberry GraphQL
- **Task Queue:** Celery + Redis
- **Vector DB:** ChromaDB for semantic memory (RAG)
- **Auth:** Supabase Auth (JWT)

### AI Orchestration (MCP)
- **Text Query:** Llama 4 (low latency, high empathy)
- **Image/Video:** Qwen 3.5 VL (high visual accuracy)
- **Complex Reasoning:** Qwen 3.5 (large context window)

## Project Structure

```
VitalPathAI/
├── VitalPathAI.xcodeproj/
│   ├── project.pbxproj
│   └── xcshareddata/xcschemes/VitalPathAI.xcscheme
└── VitalPathAI/
    ├── Sources/
    │   ├── VitalPathAIApp.swift          # App entry point
    │   ├── Models/
    │   │   └── Models.swift              # SwiftData models
    │   ├── Views/
    │   │   ├── ContentView.swift         # Home screen
    │   │   ├── ChatView.swift            # Wellness chat
    │   │   └── VideoAnalysisView.swift   # Video analysis
    │   ├── Components/
    │   │   └── GlassUIComponents.swift   # Reusable glass UI components
    │   ├── ViewModels/                   # View models (coming soon)
    │   └── Services/                     # Network & AI services (coming soon)
    └── Assets.xcassets/
        ├── AppIcon.appiconset/
        └── AccentColor.colorset/
```

## Key Components

### Glass Card
Frosted glass effect card with hover animations and subtle shadows.

### Gradient Orb
Animated background elements with blur effects.

### Pulse Button
Circular action buttons with ripple pulse animation.

### Message Bubble
Chat bubbles with gradient fills and glass overlays.

### Crisis Modal
Full-screen override for crisis situations with localized helplines.

### Video Analysis Overlay
Slide-in overlay cards for video analysis results.

### Habit Streak Ring
Animated circular progress indicator for streak tracking.

## Safety Boundaries

| Feature | ✅ ALLOWED (Wellness) | ❌ PROHIBITED (Medical) |
|---------|----------------------|------------------------|
| Diet | "This supports healthy energy levels." | "This cures diabetes." |
| Exercise | "This strengthens your legs." | "This fixes your ACL tear." |
| Mental Health | "Let's try a calming breathing exercise." | "I can treat your depression." |
| Symptoms | "Rest and hydration might help." | "You definitely have the flu." |
| Crisis | "Here is a helpline number immediately." | "I can talk you through this alone." |

## Requirements

- **iOS:** 17.0+
- **iPadOS:** 17.0+
- **Xcode:** 15.0+
- **Swift:** 5.9+

## Getting Started

1. Open `VitalPathAI.xcodeproj` in Xcode 15+
2. Select your target device (iPhone or iPad)
3. Build and run (⌘R)

## Localization

Supported languages:
- 🇺🇸 English (EN)
- 🇲🇲 Myanmar (MY)
- 🇹🇭 Thai (TH)
- 🇨🇳 Chinese (ZH)
- 🇯🇵 Japanese (JA)
- 🇰🇷 Korean (KO)

## Disclaimer

**VitalPath provides wellness guidance, not medical advice. Always consult a healthcare professional for medical concerns.**

---

Built with SwiftUI • Designed for iPhone & iPad • Wellness, Not Medicine
