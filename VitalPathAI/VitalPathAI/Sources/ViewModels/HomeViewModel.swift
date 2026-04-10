//
//  HomeViewModel.swift
//  VitalPathAI
//
//  ViewModel for Home Screen
//

import Foundation
import SwiftData

@Observable
class HomeViewModel: ObservableObject {
    var userName = "Friend"
    var dailySteps = 7532
    var moodRating: Int? = 4
    var streakCount = 5
    var crisisDetected = false
    var recentSessions: [WellnessSession] = []
    var dailyTip = "Taking small breaks throughout the day can help reduce stress and improve focus. Try the 20-20-20 rule: every 20 minutes, look at something 20 feet away for 20 seconds."
    
    private let safetyValidator = SafetyValidator.shared
    
    func startMindfulnessSession() {
        // Start breathing exercise
    }
    
    func checkForCrisis(input: String) {
        let result = safetyValidator.checkInputForCrisis(input)
        if result.isCrisis {
            crisisDetected = true
            // Log crisis event (hashed, no PHI)
        }
    }
}
