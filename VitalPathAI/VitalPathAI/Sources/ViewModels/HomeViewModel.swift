//
//  HomeViewModel.swift
//  VitalPathAI
//
//  Home Screen ViewModel with Observation Framework
//

import Foundation
import SwiftUI
import SwiftData

@Observable
class HomeViewModel {
    var userName = "Friend"
    var dailySteps = 7532
    var moodRating: Int? = 4
    var streakCount = 5
    var crisisDetected = false
    var recentSessions: [WellnessSession] = []
    var dailyTip = "Taking small breaks throughout the day can help reduce stress and improve focus. Try the 20-20-20 rule: every 20 minutes, look at something 20 feet away for 20 seconds."
    
    private let safetyValidator = SafetyValidator.shared
    
    init() {
        loadUserProfile()
        loadRecentSessions()
    }
    
    func loadUserProfile() {
        // Load from SwiftData or API
        userName = "Friend"
    }
    
    func loadRecentSessions() {
        // Load from SwiftData
        recentSessions = []
    }
    
    func startMindfulnessSession() {
        // Start breathing exercise
    }
    
    func checkForCrisis(input: String) {
        if safetyValidator.containsCrisisKeywords(input) {
            crisisDetected = true
            // Log crisis event (hashed, no PHI)
        }
    }
    
    func updateSteps(_ steps: Int) {
        dailySteps = steps
    }
    
    func updateMood(rating: Int) {
        moodRating = rating
    }
}
