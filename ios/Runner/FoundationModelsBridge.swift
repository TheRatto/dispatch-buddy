import Foundation
import Flutter
import FoundationModels

/// Custom Swift bridge for Apple Foundation Models
/// Provides Flutter access to native Foundation Models framework
@available(iOS 26.0, *)
class FoundationModelsBridge: NSObject {
    private var model: SystemLanguageModel?
    private var session: LanguageModelSession?
    private let queue = DispatchQueue(label: "foundation.models.queue")
    
    /// Initialize Foundation Models bridge
    func initialize() async throws {
        // Check model availability first
        model = SystemLanguageModel.default
        
        // Check availability status
        switch model?.availability {
        case .available:
            // Model is ready, create session
            session = LanguageModelSession()
            debugPrint("Foundation Models bridge initialized successfully")
            
        case .unavailable(.deviceNotEligible):
            throw FoundationModelsError.notAvailable("Device does not support Apple Intelligence")
            
        case .unavailable(.appleIntelligenceNotEnabled):
            throw FoundationModelsError.notAvailable("Apple Intelligence is not enabled in device settings")
            
        case .unavailable(.modelNotReady):
            throw FoundationModelsError.notAvailable("Model is downloading or not ready yet")
            
        case .unavailable(let other):
            throw FoundationModelsError.notAvailable("Model unavailable: \(other)")
            
        case .none:
            throw FoundationModelsError.notAvailable("SystemLanguageModel not available")
        }
    }
    
    /// Generate aviation briefing using Foundation Models
    func generateBriefing(prompt: String) async throws -> String {
        guard let session = session else {
            throw FoundationModelsError.sessionNotInitialized
        }
        
        // Check if session is already responding
        guard !session.isResponding else {
            throw FoundationModelsError.generationFailed("Session is already processing a request")
        }
        
        do {
            // Generate response using Foundation Models
            let response = try await session.respond(to: prompt)
            debugPrint("Foundation Models generated response successfully")
            return response.content
        } catch {
            debugPrint("Foundation Models generation failed: \(error)")
            throw FoundationModelsError.generationFailed("Failed to generate briefing: \(error.localizedDescription)")
        }
    }
    
    
    /// Check Foundation Models availability
    func checkAvailability() -> AvailabilityInfo {
        let model = SystemLanguageModel.default
        let osVersion = UIDevice.current.systemVersion
        
        switch model.availability {
        case .available:
            return AvailabilityInfo(
                isAvailable: true,
                osVersion: osVersion,
                errorMessage: nil
            )
            
        case .unavailable(.deviceNotEligible):
            return AvailabilityInfo(
                isAvailable: false,
                osVersion: osVersion,
                errorMessage: "Device does not support Apple Intelligence"
            )
            
        case .unavailable(.appleIntelligenceNotEnabled):
            return AvailabilityInfo(
                isAvailable: false,
                osVersion: osVersion,
                errorMessage: "Apple Intelligence is not enabled in device settings"
            )
            
        case .unavailable(.modelNotReady):
            return AvailabilityInfo(
                isAvailable: false,
                osVersion: osVersion,
                errorMessage: "Model is downloading or not ready yet"
            )
            
        case .unavailable(let other):
            return AvailabilityInfo(
                isAvailable: false,
                osVersion: osVersion,
                errorMessage: "Model unavailable: \(other)"
            )
        }
    }
    
    /// Cancel current operation
    func cancel() {
        // Note: Foundation Models doesn't expose cancellation API currently
        // This is a placeholder for future implementation
    }
    
    /// Dispose of resources
    func dispose() {
        session = nil
        model = nil
        debugPrint("Foundation Models resources disposed")
    }
}

// MARK: - Data Structures

struct AvailabilityInfo {
    let isAvailable: Bool
    let osVersion: String
    let errorMessage: String?
}

enum FoundationModelsError: Error, LocalizedError {
    case notAvailable(String)
    case sessionNotInitialized
    case initializationFailed(String)
    case generationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable(let message):
            return "Foundation Models not available: \(message)"
        case .sessionNotInitialized:
            return "Language model session not initialized"
        case .initializationFailed(let message):
            return "Initialization failed: \(message)"
        case .generationFailed(let message):
            return "Generation failed: \(message)"
        }
    }
}
