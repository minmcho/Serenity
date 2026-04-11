//
//  VideoAnalysisViewModel.swift
//  VitalPathAI
//
//  Video Analysis ViewModel with Observation Framework
//

import Foundation
import SwiftUI
import AVFoundation
import SwiftData

@Observable
class VideoAnalysisViewModel {
    var hasVideo = false
    var isAnalyzing = false
    var analysisComplete = false
    var analysisResult = ""
    var safetyFlagged = false
    var confidence: Double = 0.0
    var recentAnalyses: [VideoAnalysis] = []
    var videoPlayer: AVPlayer?
    
    private let safetyValidator = SafetyValidator.shared
    
    func processVideo(url: URL) {
        hasVideo = true
        videoPlayer = AVPlayer(url: url)
        analyzeVideo(url: url)
    }
    
    private func analyzeVideo(url: URL) {
        isAnalyzing = true
        
        // Simulate Qwen 3.5 VL analysis (replace with actual API call)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self else { return }
            
            self.isAnalyzing = false
            self.analysisComplete = true
            self.analysisResult = "Great balance of protein and vegetables! This meal looks nutritious and well-portioned. 🥗"
            self.safetyFlagged = false
            self.confidence = 0.92
            
            // Save analysis
            let analysis = VideoAnalysis(
                summary: "Balanced meal with high protein",
                analysisType: .meal,
                confidence: 0.92
            )
            self.recentAnalyses.insert(analysis, at: 0)
        }
    }
    
    func checkSafety(content: String) -> Bool {
        return safetyValidator.containsMedicalClaims(content)
    }
}

// MARK: - Video Analysis Model
@Model
final class VideoAnalysis {
    var id: UUID
    var summary: String
    var analysisType: AnalysisType
    var confidence: Double
    var safetyFlagged: Bool
    var timestamp: Date
    
    enum AnalysisType: String {
        case meal
        case exercise
    }
    
    init(summary: String, analysisType: AnalysisType, confidence: Double, safetyFlagged: Bool = false) {
        self.id = UUID()
        self.summary = summary
        self.analysisType = analysisType
        self.confidence = confidence
        self.safetyFlagged = safetyFlagged
        self.timestamp = Date()
    }
}
