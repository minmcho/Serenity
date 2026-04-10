//
//  VideoAnalysisViewModel.swift
//  VitalPathAI
//
//  ViewModel for Video Analysis Screen
//

import Foundation
import AVFoundation
import SwiftData

@Observable
class VideoAnalysisViewModel: ObservableObject {
    var hasVideo = false
    var isAnalyzing = false
    var analysisComplete = false
    var analysisResult = ""
    var safetyFlagged = false
    var confidence: Double = 0.0
    var recentAnalyses: [VideoAnalysis] = []
    var videoPlayer: AVPlayer?
    
    private let apiService = APIService.shared
    
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
            
            let analysis = VideoAnalysis(
                summary: "Balanced meal with high protein",
                analysisType: .meal,
                confidence: 0.92
            )
            self.recentAnalyses.insert(analysis, at: 0)
        }
    }
}
