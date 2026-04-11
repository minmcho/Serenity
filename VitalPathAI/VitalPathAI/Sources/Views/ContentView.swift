//
//  ContentView.swift
//  VitalPathAI
//
//  Main Entry Point with Glass UI
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()
    @State private var showingCrisisModal = false
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedBackground()
            
            VStack(spacing: 0) {
                // Navigation Bar
                GlassNavigationBar(
                    title: "VitalPath AI",
                    showBackButton: false,
                    onBack: nil
                )
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Welcome Section
                        WelcomeSection(userName: viewModel.userName)
                        
                        // Quick Stats
                        StatsSection(steps: viewModel.dailySteps, moodRating: viewModel.moodRating)
                        
                        // Main Action Buttons
                        QuickActionsSection(
                            onChat: { selectedTab = 1 },
                            onAnalyze: { selectedTab = 2 },
                            onBreathe: { viewModel.startMindfulnessSession() }
                        )
                        
                        // Habit Streak
                        HabitStreakSection(streakCount: viewModel.streakCount, goalDays: 7)
                        
                        // Recent Sessions
                        RecentSessionsSection(sessions: viewModel.recentSessions)
                        
                        // Wellness Tip
                        WellnessTipCard(tip: viewModel.dailyTip)
                        
                        // Mandatory Disclaimer
                        DisclaimerView()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 100) // Space for tab bar
                }
            }
            
            // Crisis Modal Overlay
            if showingCrisisModal {
                CrisisModal(
                    region: "US",
                    helplineNumber: "988",
                    helplineName: "Suicide & Crisis Lifeline",
                    onDismiss: { showingCrisisModal = false }
                )
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .navigationBarHidden(true)
        .onChange(of: viewModel.crisisDetected) { _, newValue in
            if newValue {
                showingCrisisModal = true
            }
        }
    }
}

// MARK: - Animated Background
struct AnimatedBackground: View {
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
            
            GradientOrb(color: .blue, size: 350, offset: CGPoint(x: 100, y: 150), animationDuration: 8)
            GradientOrb(color: .purple, size: 300, offset: CGPoint(x: 350, y: 450), animationDuration: 10)
            GradientOrb(color: .pink, size: 250, offset: CGPoint(x: 200, y: 700), animationDuration: 12)
        }
        .blur(radius: 60)
        .ignoresSafeArea()
    }
}

// MARK: - Welcome Section
struct WelcomeSection: View {
    let userName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Good morning, \(userName)!")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.primary, .secondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text("Ready for your wellness check-in today?")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Stats Section
struct StatsSection: View {
    let steps: Int
    let moodRating: Int?
    
    var body: some View {
        HStack(spacing: 16) {
            AnimatedStatCard(
                value: "\(steps)",
                label: "Steps Today",
                trend: .up(12.5),
                icon: "figure.walk"
            )
            
            AnimatedStatCard(
                value: moodRating != nil ? "\(moodRating!)/5" : "--",
                label: "Mood Rating",
                trend: moodRating != nil && moodRating! >= 4 ? .up(5.0) : .neutral,
                icon: "heart.fill"
            )
        }
    }
}

// MARK: - Quick Actions Section
struct QuickActionsSection: View {
    let onChat: () -> Void
    let onAnalyze: () -> Void
    let onBreathe: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                PulseButton(title: "Chat", systemImage: "message.fill", color: .blue, action: onChat)
                PulseButton(title: "Analyze", systemImage: "camera.fill", color: .purple, action: onAnalyze)
                PulseButton(title: "Breathe", systemImage: "wind", color: .teal, action: onBreathe)
            }
        }
    }
}

// MARK: - Habit Streak Section
struct HabitStreakSection: View {
    let streakCount: Int
    let goalDays: Int
    
    var body: some View {
        GlassCard(
            title: "Current Streak",
            subtitle: "Keep going! You're doing great.",
            icon: "flame.fill",
            color: .orange
        ) {
            // Navigate to habits
        }
        .overlay(
            HabitStreakRing(streakCount: streakCount, goalDays: goalDays, color: .orange)
                .scaleEffect(0.8)
                .offset(x: 120, y: -10)
        )
    }
}

// MARK: - Recent Sessions Section
struct RecentSessionsSection: View {
    let sessions: [WellnessSession]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to all sessions
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
            
            if sessions.isEmpty {
                GlassSkeleton(height: 80, width: nil, cornerRadius: 16)
            } else {
                ForEach(sessions.prefix(3), id: \.id) { session in
                    SessionRow(session: session)
                }
            }
        }
    }
}

// MARK: - Session Row
struct SessionRow: View {
    let session: WellnessSession
    
    var icon: String {
        switch session.sessionType {
        case .chat: return "message.fill"
        case .videoAnalysis: return "camera.fill"
        case .habitCheckin: return "checkmark.circle.fill"
        case .mindfulnessExercise: return "wind"
        }
    }
    
    var color: Color {
        switch session.sessionType {
        case .chat: return .blue
        case .videoAnalysis: return .purple
        case .habitCheckin: return .green
        case .mindfulnessExercise: return .teal
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.activityDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(session.completedAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color.secondary.opacity(0.6))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Wellness Tip Card
struct WellnessTipCard: View {
    let tip: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.yellow)
                
                Text("Daily Wellness Tip")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Text(tip)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.yellow.opacity(0.15), Color.orange.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Disclaimer View
struct DisclaimerView: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.caption)
                Text("Wellness, Not Medicine")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.secondary)
            
            Text("VitalPath provides wellness guidance, not medical advice. Always consult a healthcare professional for medical concerns.")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [WellnessSession.self, WellnessProfile.self, WearableConnection.self])
}
