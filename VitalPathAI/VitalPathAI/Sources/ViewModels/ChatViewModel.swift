//
//  ChatViewModel.swift
//  VitalPathAI
//
//  ViewModel for Chat Screen
//

import Foundation
import SwiftData

@Observable
class ChatViewModel: ObservableObject {
    var messages: [ChatMessage] = []
    var isTyping = false
    var crisisDetected = false
    var userRegion = "US"
    var crisisHelplineNumber = "988"
    var crisisHelplineName = "Suicide & Crisis Lifeline"
    
    private let sessionId = UUID().uuidString
    private let safetyValidator = SafetyValidator.shared
    
    init() {
        addBotMessage("Hi! I'm your wellness companion. How are you feeling today? Remember, I provide wellness support, not medical advice.")
    }
    
    func sendMessage(_ text: String) {
        if checkForCrisis(input: text) {
            return
        }
        
        let userMessage = ChatMessage(sessionId: sessionId, content: text, isUser: true)
        messages.append(userMessage)
        
        isTyping = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            let response = generateWellnessResponse(to: text)
            self.addBotMessage(response)
            self.isTyping = false
        }
    }
    
    private func addBotMessage(_ content: String) {
        let botMessage = ChatMessage(sessionId: sessionId, content: content, isUser: false)
        messages.append(botMessage)
    }
    
    private func checkForCrisis(input: String) -> Bool {
        let result = safetyValidator.checkInputForCrisis(input)
        if result.isCrisis {
            crisisDetected = true
            crisisHelplineNumber = result.helplineNumber
            crisisHelplineName = result.helplineName
            return true
        }
        return false
    }
    
    private func generateWellnessResponse(to input: String) -> String {
        let lowercaseInput = input.lowercased()
        
        if lowercaseInput.contains("stress") || lowercaseInput.contains("anxious") {
            return "It's completely normal to feel stressed sometimes. Would you like to try a 2-minute breathing exercise? I can guide you through it."
        } else if lowercaseInput.contains("tired") || lowercaseInput.contains("sleep") {
            return "Rest is so important for our wellbeing. Have you been getting enough sleep lately? Try establishing a calming bedtime routine."
        } else if lowercaseInput.contains("happy") || lowercaseInput.contains("great") {
            return "That's wonderful to hear! 🌟 What's been going well for you? Celebrating the positive moments is important too."
        } else {
            return "Thank you for sharing that with me. How has this been affecting your daily life? I'm here to listen and support your wellness journey."
        }
    }
}
