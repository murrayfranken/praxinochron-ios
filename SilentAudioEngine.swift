import Foundation
import AVFoundation
import UIKit

class SilentAudioEngine {
    static let shared = SilentAudioEngine()
    private var audioPlayer: AVAudioPlayer?
    private(set) var isInterrupted = false
    
    init() {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("silence.caf")
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1) else { return }
        
        do {
            let file = try AVAudioFile(forWriting: url, settings: format.settings)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(format.sampleRate)) else { return }
            buffer.frameLength = buffer.frameCapacity
            
            try file.write(from: buffer)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Infinite loop
            audioPlayer?.volume = 0.01 // Must be > 0.0 so iOS doesn't cull the null audio pipeline
            audioPlayer?.prepareToPlay()
            
            // Layer 1: Listen for OS media locks taking over or releasing
            NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
        } catch {
            print("Failed to initialize silent player: \(error.localizedDescription)")
        }
    }

    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        if type == .began {
            isInterrupted = true
            print("SilentAudioEngine: Interrupted by iOS (Safari/Media taking exclusive lock)")
        } else if type == .ended {
            isInterrupted = false
            print("SilentAudioEngine: Interruption ended. Healing audio channel.")
            try? AVAudioSession.sharedInstance().setActive(true)
            audioPlayer?.play()
        }
    }

    func start() {
        audioPlayer?.play()
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
    }
}
