//
//  SafetyValidator.swift
//  VitalPathAI
//
//  Safety Validation for Wellness Boundaries
//

import Foundation

/// Validates inputs and outputs for safety compliance
class SafetyValidator {
    
    static let shared = SafetyValidator()
    
    private let crisisKeywords = [
        "suicide", "kill myself", "hurt myself", "overdose",
        "end my life", "self harm", "die", "death wish"
    ]
    
    private let medicalClaims = [
        "cure", "diagnose", "prescribe", "treat", "medication",
        "dosage", "side effect", "clinical trial", "FDA approved"
    ]
    
    /// Check input for crisis keywords
    func checkInputForCrisis(_ input: String) -> CrisisDetectionResult {
        let lowercased = input.lowercased()
        
        let detectedKeywords = crisisKeywords.filter { lowercased.contains($0) }
        
        if !detectedKeywords.isEmpty {
            return CrisisDetectionResult(
                isCrisis: true,
                keywords: detectedKeywords,
                helplineNumber: getHelplineForRegion(),
                helplineName: getHelplineName()
            )
        }
        
        return CrisisDetectionResult(isCrisis: false, keywords: [], helplineNumber: "", helplineName: "")
    }
    
    /// Check output for prohibited medical claims
    func checkOutputForMedicalClaims(_ output: String) -> Bool {
        let lowercased = output.lowercased()
        return medicalClaims.contains { lowercased.contains($0) }
    }
    
    /// Sanitize response to ensure wellness boundaries
    func sanitizeResponse(_ response: String) -> String {
        var sanitized = response
        
        // Replace medical claims with wellness language
        medicalClaims.forEach { claim in
            sanitized = sanitized.replacingOccurrences(of: claim, with: "support")
        }
        
        return sanitized
    }
    
    private func getHelplineForRegion() -> String {
        // In production, detect region from user settings
        return "988" // US default
    }
    
    private func getHelplineName() -> String {
        return "Suicide & Crisis Lifeline"
    }
}

struct CrisisDetectionResult {
    let isCrisis: Bool
    let keywords: [String]
    let helplineNumber: String
    let helplineName: String
}
