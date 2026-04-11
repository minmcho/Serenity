//
//  ChatViewModel.swift
//  VitalPathAI
//
//  Chat ViewModel with Observation Framework
//

import Foundation
import SwiftUI
import SwiftData

@Observable
class ChatViewModel {
    var messages: [ChatMessage] = []
    var isTyping = false
    var crisisDetected = false
    var userRegion = "US"
    var crisisHelplineNumber = "988"
    var crisisHelplineName = "Suicide & Crisis Lifeline"
    
    private let sessionId = UUID().uuidString
    private let safetyValidator = SafetyValidator.shared
    
    init() {
        // Add welcome message
        addBotMessage("Hi! I'm your wellness companion. How are you feeling today? Remember, I provide wellness support, not medical advice.")
    }
    
    func sendMessage(_ text: String) {
        // Check for crisis keywords first
        if checkForCrisis(input: text) {
            return
        }
        
        // Add user message
        let userMessage = ChatMessage(sessionId: sessionId, content: text, isUser: true)
        messages.append(userMessage)
        
        // Simulate AI typing
        isTyping = true
        
        // Simulate AI response (replace with actual API call)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            // Safety check on output would happen here
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
        if safetyValidator.containsCrisisKeywords(input) {
            crisisDetected = true
            // Update helpline based on region
            updateHelplineForRegion()
            // Log crisis event (hashed, no PHI stored)
            return true
        }
        return false
    }
    
    private func updateHelplineForRegion() {
        switch userRegion {
        case "TH":
            crisisHelplineNumber = "1323"
            crisisHelplineName = "Thai Mental Health Hotline"
        case "JP":
            crisisHelplineNumber = "0120-783-556"
            crisisHelplineName = "Inochi-no-Denwa"
        case "KR":
            crisisHelplineNumber = "109"
            crisisHelplineName = "Korea Suicide Prevention Center"
        case "MM":
            crisisHelplineNumber = "09-777-5544"
            crisisHelplineName = "Myanmar Mental Health Helpline"
        case "MY":
            crisisHelplineNumber = "03-7956-8144"
            crisisHelplineName = "Befrienders KL"
        default:
            crisisHelplineNumber = "988"
            crisisHelplineName = "Suicide & Crisis Lifeline"
        }
    }
    
    private func generateWellnessResponse(to input: String) -> String {
        // This would be replaced with actual Llama 4 API call
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
