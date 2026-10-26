import AVFoundation
import os

enum AudioFocusMode: Int {
    case off = 0
    case lower = 1
    case pause = 2
}

enum AudioFocusManager {
    private static let logger = Logger(subsystem: Constants.logTagTimer, category: "AudioFocus")
    
    static func setFocus(mode: Int) {
        guard let focusMode = AudioFocusMode(rawValue: mode), focusMode != .off else { return }
        
        let session = AVAudioSession.sharedInstance()
        
        do {
            if focusMode == .pause {
                try session.setCategory(.playback, mode: .spokenAudio)
            } else {
                try session.setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers, .duckOthers])
            }
            try session.setActive(true)
        } catch {
            logger.error("Failed to activate audio session: \(error.localizedDescription)")
        }
    }
    
    static func releaseFocus() {
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            logger.error("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }
}
