import AVFoundation
import os

actor TtsManager {
    static let shared = TtsManager()
    
    private let synthesizer = AVSpeechSynthesizer()
    private let logger = Logger(subsystem: "com.praxinoscopemedia.praxinochron", category: "TtsManager")
    private var fallbackTrackers = Set<ObjectIdentifier>()
    private let delegate: SpeechDelegate
    
    private init() {
        let newDelegate = SpeechDelegate()
        self.delegate = newDelegate
        synthesizer.delegate = newDelegate
        newDelegate.setActor(self)
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        Task { @MainActor in
            AudioFocusManager.releaseFocus()
        }
    }
    
    func speak(text: String, rate: Float = 1.0, pitch: Float = 1.0, volume: Float = 1.0) async {
        let interrupted = await MainActor.run { SilentAudioEngine.shared.isInterrupted }
        if interrupted {
            logger.debug("Audio hardware locked by iOS. Bypassing TTS to prevent queue crash: \(text)")
            return
        }

        logger.debug("Speaking: \(text)")
        
        await MainActor.run {
            AudioFocusManager.setFocus()
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate * AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = pitch
        utterance.volume = volume
        
        synthesizer.speak(utterance)
    }
    
    func handleDone(utterance: AVSpeechUtterance) {
        fallbackTrackers.remove(ObjectIdentifier(utterance))
        Task { @MainActor in
            AudioFocusManager.releaseFocus()
        }
    }
    
    func handleError(utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        if !fallbackTrackers.contains(id) {
            let fallbackUtterance = AVSpeechUtterance(string: utterance.speechString)
            fallbackUtterance.rate = AVSpeechUtteranceDefaultSpeechRate
            fallbackUtterance.pitchMultiplier = 1.0
            fallbackUtterance.volume = utterance.volume
            
            fallbackTrackers.insert(ObjectIdentifier(fallbackUtterance))
            synthesizer.speak(fallbackUtterance)
        } else {
            fallbackTrackers.remove(id)
            Task { @MainActor in
                AudioFocusManager.releaseFocus()
            }
        }
    }
}

final class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    private unowned var actor: TtsManager?
    
    func setActor(_ actor: TtsManager) {
        self.actor = actor
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let capturedActor = actor
        Task {
            await capturedActor?.handleDone(utterance: utterance)
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let capturedActor = actor
        Task {
            await capturedActor?.handleError(utterance: utterance)
        }
    }
}
// 94 lines in v1.3
