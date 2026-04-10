//
//  GlassUIComponents.swift
//  VitalPathAI
//
//  Apple-style Rich Glass UI Components with Smooth Animations
//  Designed for iPhone & iPad with iOS 17+ @Observable pattern
//

import SwiftUI

// MARK: - Glass Card Component
/// Frosted glass effect card with subtle shadows and animations
struct GlassCard: View {
    let title: String
    let subtitle: String?
    let icon: String
    let color: Color
    let action: (() -> Void)?
    
    @State private var isHovering = false
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Button(action: { action?() }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.2))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(color)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.-semibold)
                            .foregroundColor(.primary)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.tertiary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.7), Color.white.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.8), Color.white.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: color.opacity(0.3), radius: isHovering ? 12 : 8, x: 0, y: isHovering ? 4 : 2)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                    )
            )
            .scaleEffect(scale)
            .animation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0), value: isHovering)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
                scale = hovering ? 1.02 : 1.0
            }
        }
    }
}

// MARK: - Gradient Orb Background
/// Animated gradient orbs for rich background effects
struct GradientOrb: View {
    let color: Color
    let size: CGFloat
    let offset: CGPoint
    let animationDuration: Double
    
    @State private var animate = false
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(0.6), color.opacity(0.1)],
                    center: .center,
                    startRadius: 0,
                    endRadius: size
                )
            )
            .frame(width: size, height: size)
            .position(x: offset.x, y: offset.y)
            .blur(radius: 40)
            .onAppear {
                withAnimation(.linear(duration: animationDuration).repeatForever(autoreverses: true)) {
                    animate.toggle()
                }
            }
    }
}

// MARK: - Glass Navigation Bar
struct GlassNavigationBar: View {
    let title: String
    let showBackButton: Bool
    let onBack: (() -> Void)?
    
    var body: some View {
        HStack {
            if showBackButton {
                Button(action: { onBack?() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.accentColor)
                }
            }
            
            Spacer()
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            // Placeholder for balance
            Color.clear.frame(width: showBackButton ? 60 : 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Animated Stat Card
struct AnimatedStatCard: View {
    let value: String
    let label: String
    let trend: Trend?
    let icon: String
    
    enum Trend {
        case up(Double)
        case down(Double)
        case neutral
    }
    
    @State private var displayValue = "0"
    @State private var opacity = 0.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let trend = trend {
                    switch trend {
                    case .up(let percentage):
                        Label("\(percentage)%", systemImage: "arrow.up.right")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    case .down(let percentage):
                        Label("\(percentage)%", systemImage: "arrow.down.right")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    case .neutral:
                        EmptyView()
                    }
                }
            }
            
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.primary, .secondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                opacity = 1.0
            }
        }
    }
}

// MARK: - Pulse Button
struct PulseButton: View {
    let title: String
    let systemImage: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var showingPulse = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            showingPulse = true
            action()
        }) {
            ZStack {
                if showingPulse {
                    Circle()
                        .stroke(color.opacity(0.4), lineWidth: 3)
                        .frame(width: 80, height: 80)
                        .scaleEffect(isPressed ? 1.2 : 1.0)
                        .opacity(isPressed ? 0 : 1)
                }
                
                VStack(spacing: 8) {
                    Image(systemName: systemImage)
                        .font(.system(size: 24, weight: .semibold))
                    
                    Text(title)
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
            }
            .frame(width: 70, height: 70)
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onChange(of: showingPulse) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation {
                        showingPulse = false
                    }
                }
            }
        }
    }
}

// MARK: - Message Bubble (Chat)
struct MessageBubble: View {
    let message: String
    let isUser: Bool
    let timestamp: Date
    
    var body: some View {
        HStack {
            if !isUser {
                Spacer()
            }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                isUser ?
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [Color.white.opacity(0.9), Color.white.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: isUser ? Color.accentColor.opacity(0.3) : Color.black.opacity(0.1), radius: 6, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isUser ? Color.clear : Color.white.opacity(0.5),
                                lineWidth: 1
                            )
                    )
                
                Text(timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if isUser {
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Crisis Modal (Full Screen Override)
struct CrisisModal: View {
    let region: String
    let helplineNumber: String
    let helplineName: String
    let onDismiss: () -> Void
    
    @State private var scale = 0.8
    @State private var opacity = 0.0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("We're Here to Help")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("It sounds like you're going through a difficult time. Please reach out to a crisis helpline immediately.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    Text(helplineName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(helplineNumber)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.2))
                        )
                }
                
                Button(action: onDismiss) {
                    Text("I Understand")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                }
                .padding(.top, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [Color.gray.opacity(0.9), Color.black.opacity(0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .padding(32)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

// MARK: - Video Analysis Overlay Card
struct VideoAnalysisOverlay: View {
    let analysisResult: String
    let safetyFlagged: Bool
    let confidence: Double
    
    @State private var slideIn = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: safetyFlagged ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundColor(safetyFlagged ? .orange : .green)
                    
                    Text(safetyFlagged ? "Review Needed" : "Analysis Complete")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                Text(analysisResult)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(3)
                
                ProgressView(value: confidence)
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    .frame(height: 4)
                
                Text("Confidence: \(Int(confidence * 100))%")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .padding(16)
        .offset(y: slideIn ? 0 : 100)
        .opacity(slideIn ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)) {
                slideIn = true
            }
        }
    }
}

// MARK: - Habit Streak Ring
struct HabitStreakRing: View {
    let streakCount: Int
    let goalDays: Int
    let color: Color
    
    @State private var progress: CGFloat = 0.0
    
    private var progressRatio: CGFloat {
        min(CGFloat(streakCount) / CGFloat(goalDays), 1.0)
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                .frame(width: 120, height: 120)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [color, color.opacity(0.6)]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 4) {
                Text("\(streakCount)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("day streak")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                progress = progressRatio
            }
        }
    }
}

// MARK: - Loading Skeleton
struct GlassSkeleton: View {
    let height: CGFloat
    let width: CGFloat?
    let cornerRadius: CGFloat
    
    @State private var shimmer = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.2),
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.2)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    shimmer = true
                }
            }
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 20) {
            GlassCard(
                title: "Today's Wellness Check",
                subtitle: "Track your mood and activities",
                icon: "heart.fill",
                color: .pink
            ) {}
            
            AnimatedStatCard(
                value: "7,532",
                label: "Steps Today",
                trend: .up(12.5),
                icon: "figure.walk"
            )
            
            HStack(spacing: 16) {
                PulseButton(title: "Chat", systemImage: "message.fill", color: .blue) {}
                PulseButton(title: "Analyze", systemImage: "camera.fill", color: .purple) {}
                PulseButton(title: "Breathe", systemImage: "wind", color: .teal) {}
            }
            
            HabitStreakRing(streakCount: 5, goalDays: 7, color: .orange)
            
            MessageBubble(
                message: "Great job on completing your mindfulness session today! How are you feeling?",
                isUser: false,
                timestamp: Date()
            )
            
            MessageBubble(
                message: "Feeling much better after the breathing exercise!",
                isUser: true,
                timestamp: Date()
            )
        }
        .padding()
        .background(
            ZStack {
                GradientOrb(color: .blue, size: 300, offset: CGPoint(x: 50, y: 100), animationDuration: 8)
                GradientOrb(color: .purple, size: 250, offset: CGPoint(x: 300, y: 400), animationDuration: 10)
                GradientOrb(color: .pink, size: 200, offset: CGPoint(x: 200, y: 600), animationDuration: 12)
            }
            .blur(radius: 50)
        )
    }
}
