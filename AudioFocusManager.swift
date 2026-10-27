import AVFoundation
import os

enum AudioFocusManager {
    private static let logger = Logger(subsystem: Constants.logTagTimer, category: "AudioFocus")
    
    static func setFocus() {
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            logger.error("Failed to activate audio session: \(error.localizedDescription)")
        }
    }
    
    static func releaseFocus() {
    }
}
