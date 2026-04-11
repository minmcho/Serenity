//
//  Models.swift
//  VitalPathAI
//
//  Data Models for Wellness Tracking
//

import Foundation
import SwiftData

// MARK: - WellnessProfile
/// Stores user preferences and wellness context for AI personalization
@Model
final class WellnessProfile {
    var id: UUID
    var userId: String
    var dietaryPreferences: [String]  // e.g., ["vegetarian", "gluten-free"]
    var healthConditions: [String]    // e.g., ["knee pain", "high blood pressure"]
    var fitnessLevel: FitnessLevel
    var preferredLanguages: [String]
    var createdAt: Date
    var updatedAt: Date
    
    enum FitnessLevel: String, Codable, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        
        var description: String {
            switch self {
            case .beginner: return "Just starting out"
            case .intermediate: return "Regularly active"
            case .advanced: return "Very active"
            }
        }
    }
    
    init(userId: String, dietaryPreferences: [String] = [], healthConditions: [String] = [], fitnessLevel: FitnessLevel = .beginner, preferredLanguages: [String] = ["en"]) {
        self.id = UUID()
        self.userId = userId
        self.dietaryPreferences = dietaryPreferences
        self.healthConditions = healthConditions
        self.fitnessLevel = fitnessLevel
        self.preferredLanguages = preferredLanguages
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - WellnessSession
/// Tracks individual wellness activities and AI interactions
@Model
final class WellnessSession {
    var id: UUID
    var sessionId: String
    var userId: String
    var sessionType: SessionType
    var activityDescription: String
    var aiResponse: String?
    var safetyFlagged: Bool
    var moodRating: Int?  // 1-5 scale
    var duration: TimeInterval
    var completedAt: Date
    var syncedToCloud: Bool
    
    enum SessionType: String, Codable {
        case chat = "chat"
        case videoAnalysis = "video_analysis"
        case habitCheckin = "habit_checkin"
        case mindfulnessExercise = "mindfulness_exercise"
    }
    
    init(sessionId: String, userId: String, sessionType: SessionType, activityDescription: String, duration: TimeInterval = 0) {
        self.id = UUID()
        self.sessionId = sessionId
        self.userId = userId
        self.sessionType = sessionType
        self.activityDescription = activityDescription
        self.safetyFlagged = false
        self.duration = duration
        self.completedAt = Date()
        self.syncedToCloud = false
    }
}

// MARK: - WearableConnection
/// Manages Apple HealthKit integration
@Model
final class WearableConnection {
    var id: UUID
    var userId: String
    var isConnected: Bool
    var lastSyncDate: Date?
    var dailySteps: Int
    var averageHeartRate: Double?
    var permissionsGranted: Set<String>
    
    init(userId: String) {
        self.id = UUID()
        self.userId = userId
        self.isConnected = false
        self.dailySteps = 0
        self.permissionsGranted = []
    }
}

// MARK: - CrisisEvent
/// Audit log for crisis interventions (no PHI stored)
@Model
final class CrisisEvent {
    var id: UUID
    var hashedInput: String  // Hashed for privacy
    var detectedKeywords: [String]
    var region: String
    var helplineDisplayed: String
    var timestamp: Date
    
    init(hashedInput: String, detectedKeywords: [String], region: String, helplineDisplayed: String) {
        self.id = UUID()
        self.hashedInput = hashedInput
        self.detectedKeywords = detectedKeywords
        self.region = region
        self.helplineDisplayed = helplineDisplayed
        self.timestamp = Date()
    }
}
