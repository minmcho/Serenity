//
//  ChatView.swift
//  VitalPathAI
//
//  Intelligent Wellness Chat with Glass UI
//

import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ChatViewModel()
    @State private var messageText = ""
    @State private var showingCrisisModal = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            // Animated background
            AnimatedBackground()
            
            VStack(spacing: 0) {
                // Navigation Bar
                GlassNavigationBar(
                    title: "Wellness Chat",
                    showBackButton: true,
                    onBack: { /* Navigate back */ }
                )
                
                // Chat Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(
                                    message: message.content,
                                    isUser: message.isUser,
                                    timestamp: message.timestamp
                                )
                                .id(message.id)
                            }
                            
                            if viewModel.isTyping {
                                TypingIndicator()
                                    .transition(.opacity)
                            }
                        }
                        .padding(.vertical)
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Safety Disclaimer Banner
                if !viewModel.messages.isEmpty {
                    SafetyBanner()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Input Field
                ChatInputField(
                    text: $messageText,
                    isFocused: _isTextFieldFocused,
                    onSend: sendMessage
                )
            }
            
            // Crisis Modal Overlay
            if showingCrisisModal {
                CrisisModal(
                    region: viewModel.userRegion,
                    helplineNumber: viewModel.crisisHelplineNumber,
                    helplineName: viewModel.crisisHelplineName,
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
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let userMessage = messageText
        messageText = ""
        isTextFieldFocused = false
        
        viewModel.sendMessage(userMessage)
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var bounceOffsets: [CGFloat] = [0, 0, 0]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.secondary.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .offset(y: bounceOffsets[index])
                    .animation(
                        Animation.easeInOut(duration: 0.4)
                            .repeatForever()
                            .delay(Double(index) * 0.15),
                        value: bounceOffsets[index]
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation {
                bounceOffsets = [-4, -6, -4]
            }
        }
    }
}

// MARK: - Safety Banner
struct SafetyBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "shield.fill")
                .font(.caption)
                .foregroundColor(.blue)
            
            Text("Wellness guidance only. Not medical advice.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
        )
        .padding(.horizontal)
    }
}

// MARK: - Chat Input Field
struct ChatInputField: View {
    @Binding var text: String
    @FocusState var isFocused: Bool
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                // Voice input
            }) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
            
            TextField("Share how you're feeling...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .focused($isFocused)
                .padding(.vertical, 8)
            
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(text.trimmingCharacters(in: .whitespaces).isEmpty ? Color.secondary.opacity(0.5) : .accentColor)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .cornerRadius(24)
        .padding()
    }
}

// MARK: - Chat Message Model
@Model
final class ChatMessage {
    var id: UUID
    var sessionId: String
    var content: String
    var isUser: Bool
    var safetyFlagged: Bool
    var timestamp: Date
    
    init(sessionId: String, content: String, isUser: Bool) {
        self.id = UUID()
        self.sessionId = sessionId
        self.content = content
        self.isUser = isUser
        self.safetyFlagged = false
        self.timestamp = Date()
    }
}

#Preview {
    ChatView()
        .modelContainer(for: [ChatMessage.self, WellnessSession.self])
}
