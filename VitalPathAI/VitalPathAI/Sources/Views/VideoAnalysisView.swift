//
//  VideoAnalysisView.swift
//  VitalPathAI
//
//  Multi-Modal Video Analysis with Glass UI Overlay
//

import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

struct VideoAnalysisView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservableObject private var viewModel = VideoAnalysisViewModel()
    @State private var showingVideoPicker = false
    @State private var showingCamera = false
    
    var body: some View {
        ZStack {
            // Animated background
            AnimatedBackground()
            
            VStack(spacing: 0) {
                // Navigation Bar
                GlassNavigationBar(
                    title: "Analyze Meal or Exercise",
                    showBackButton: true,
                    onBack: { /* Navigate back */ }
                )
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Camera Preview / Upload Area
                        CameraCaptureSection(
                            viewModel: viewModel,
                            onShowCamera: { showingCamera = true },
                            onShowPicker: { showingVideoPicker = true }
                        )
                        
                        // Analysis Result Overlay (when available)
                        if viewModel.analysisComplete {
                            VideoAnalysisOverlay(
                                analysisResult: viewModel.analysisResult,
                                safetyFlagged: viewModel.safetyFlagged,
                                confidence: viewModel.confidence
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                        }
                        
                        // Instructions
                        InstructionsCard()
                        
                        // Safety Guidelines
                        SafetyGuidelinesCard()
                        
                        // Recent Analyses
                        RecentAnalysesSection(analyses: viewModel.recentAnalyses)
                        
                        // Mandatory Disclaimer
                        DisclaimerView()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            
            // Loading Overlay
            if viewModel.isAnalyzing {
                AnalysisLoadingOverlay()
                    .zIndex(100)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingCamera) {
            CameraView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingVideoPicker) {
            VideoPickerView(viewModel: viewModel)
        }
    }
}

// MARK: - Camera Capture Section
struct CameraCaptureSection: View {
    @ObservedObject var viewModel: VideoAnalysisViewModel
    let onShowCamera: () -> Void
    let onShowPicker: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .frame(height: 280)
                
                if viewModel.hasVideo {
                    // Video preview would go here
                    VideoPlayer(player: viewModel.videoPlayer)
                        .cornerRadius(24)
                        .clipped()
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("Record or Upload")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Show us your meal or exercise form")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 16) {
                            Button(action: onShowCamera) {
                                Label("Record", systemImage: "record.circle")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.red, .red.opacity(0.7)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    )
                            }
                            
                            Button(action: onShowPicker) {
                                Label("Upload", systemImage: "photo.on.rectangle")
                                    .font(.headline)
                                    .foregroundColor(.accentColor)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(
                                        Capsule()
                                            .fill(Color.accentColor.opacity(0.15))
                                    )
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Instructions Card
struct InstructionsCard: View {
    var body: some View {
        GlassCard(
            title: "How It Works",
            subtitle: "Get instant wellness feedback on your meals or exercises",
            icon: "lightbulb.fill",
            color: .yellow
        ) {
            // Show detailed instructions
        }
        .overlay(
            VStack(alignment: .leading, spacing: 8) {
                InstructionRow(icon: "number.circle.fill", text: "Record up to 30 seconds")
                InstructionRow(icon: "number.circle.fill", text: "Show the full meal or exercise")
                InstructionRow(icon: "number.circle.fill", text: "Get instant AI-powered feedback")
            }
            .padding(.top, 80)
            .padding(.horizontal, 60)
        )
    }
}

struct InstructionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.accentColor)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Safety Guidelines Card
struct SafetyGuidelinesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.green)
                
                Text("Safety First")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            Text("Our AI provides wellness guidance only. For medical concerns, always consult a healthcare professional.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                Label("Wellness Tips", systemImage: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.green)
                Label("No Diagnosis", systemImage: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Recent Analyses Section
struct RecentAnalysesSection: View {
    let analyses: [VideoAnalysis]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Analyses")
                .font(.headline)
                .foregroundColor(.primary)
            
            if analyses.isEmpty {
                GlassSkeleton(height: 60, width: nil, cornerRadius: 12)
            } else {
                ForEach(analyses.prefix(3)) { analysis in
                    AnalysisRow(analysis: analysis)
                }
            }
        }
    }
}

struct AnalysisRow: View {
    let analysis: VideoAnalysis
    
    var icon: String {
        analysis.analysisType == .meal ? "fork.knife" : "figure.run"
    }
    
    var color: Color {
        analysis.analysisType == .meal ? .orange : .blue
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(analysis.summary)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(analysis.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if analysis.safetyFlagged {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Analysis Loading Overlay
struct AnalysisLoadingOverlay: View {
    @State private var rotation = 0.0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.accentColor)
                
                Text("Analyzing your video...")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("This usually takes 5-10 seconds")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Camera View
struct CameraView: UIViewRepresentable {
    func updateUIView(_ uiView: UIView, context: Context) {}

    let viewModel: VideoAnalysisViewModel
    
    func makeUIView(context: Context) -> UIView {
        // Camera implementation would go here
        return UIView()
    }
}

// MARK: - Video Picker View
struct VideoPickerView: UIViewControllerRepresentable {
    let viewModel: VideoAnalysisViewModel
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [UTType.movie.identifier]
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let viewModel: VideoAnalysisViewModel
        
        init(viewModel: VideoAnalysisViewModel) {
            self.viewModel = viewModel
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let videoURL = info[.mediaURL] as? URL {
                viewModel.processVideo(url: videoURL)
            }
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Video Analysis ViewModel
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

#Preview {
    VideoAnalysisView()
        .modelContainer(for: [VideoAnalysis.self, WellnessSession.self])
}
