//
//  VitalPathAIApp.swift
//  VitalPathAI
//
//  Safety-First Wellness Coaching Platform
//  Core Philosophy: "Wellness, Not Medicine"
//

import SwiftUI

@main
struct VitalPathAIApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .modelContainer(for: [WellnessSession.self, WellnessProfile.self, WearableConnection.self])
        }
    }
}

/// Global application state manager
@Observable
class AppState {
    var isAuthenticated = false
    var currentLanguage: SupportedLanguage = .english
    var isOffline = false
    var circuitBreakerOpen = false
    
    enum SupportedLanguage: String, CaseIterable {
        case english = "en"
        case myanmar = "my"
        case thai = "th"
        case chinese = "zh"
        case japanese = "ja"
        case korean = "ko"
    }
}
