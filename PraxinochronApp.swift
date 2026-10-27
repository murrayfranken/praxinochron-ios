import SwiftUI
import AVFoundation

@main
struct PraxinochronApp: App {
    
    init() {
        setupAudioSession()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    UIApplication.shared.isIdleTimerDisabled = true
                }
                .onDisappear {
                    UIApplication.shared.isIdleTimerDisabled = false
                }
        }
    }
    
    private func setupAudioSession() {
            do {
                try AVAudioSession.sharedInstance().setCategory(
                    .playback,
                    mode: .default,
                    options: [.mixWithOthers, .duckOthers]
                )
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
