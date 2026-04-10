//
//  APIService.swift
//  VitalPathAI
//
//  API Service for AI Communication
//

import Foundation

/// Safety-first API service for wellness AI communication
@Observable
class APIService {
    static let shared = APIService()
    
    private var circuitBreakerOpen = false
    private var consecutiveFailures = 0
    private let maxFailures = 5
    
    enum APIError: Error {
        case networkError
        case serverError
        case circuitBreakerOpen
        case unsafeResponse
    }
    
    /// Send text to Llama 4 for wellness coaching
    func sendTextQuery(_ text: String, context: [String: Any]) async throws -> String {
        guard !circuitBreakerOpen else {
            throw APIError.circuitBreakerOpen
        }
        
        // Simulate API call (replace with actual implementation)
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Safety validation would happen here
        return "Wellness response generated safely"
    }
    
    /// Send video frames to Qwen 3.5 VL for analysis
    func analyzeVideo(_ videoData: Data) async throws -> VideoAnalysisResult {
        guard !circuitBreakerOpen else {
            throw APIError.circuitBreakerOpen
        }
        
        // Simulate API call
        try await Task.sleep(nanoseconds: 3_000_000_000)
        
        return VideoAnalysisResult(
            nutritionEstimate: "Balanced meal",
            safetyFlagged: false,
            confidence: 0.92
        )
    }
    
    /// Record failure for circuit breaker
    func recordFailure() {
        consecutiveFailures += 1
        if consecutiveFailures >= maxFailures {
            circuitBreakerOpen = true
        }
    }
    
    /// Record success and reset circuit breaker
    func recordSuccess() {
        consecutiveFailures = 0
        circuitBreakerOpen = false
    }
}

struct VideoAnalysisResult {
    let nutritionEstimate: String
    let safetyFlagged: Bool
    let confidence: Double
}
