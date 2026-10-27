import Foundation
import AudioToolbox
import Combine
import UIKit

@MainActor
final class TimerEngine: ObservableObject {
    static let shared = TimerEngine()
    
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var timeRemainingDisplay = ""
    @Published var currentIntervalDisplay = ""
    
    private var timerTask: Task<Void, Never>?
    private var pauseAlarmTask: Task<Void, Never>?
    private var targetEndDate: Date?
    private var timeRemainingSeconds: Int = 0
    
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    func start() {
        isRunning = true
        isPaused = false
        SilentAudioEngine.shared.start()
        
        let totalMinutes = defaults.integer(forKey: Constants.prefTotalTime)
        let intervalMinutes = defaults.integer(forKey: Constants.prefIntervalTime)
        let isSecondsMode = defaults.bool(forKey: Constants.prefIsSecondsMode)
        let timerName = defaults.string(forKey: Constants.prefTimerName) ?? ""
        let speakName = defaults.object(forKey: Constants.prefSpeakName) as? Bool ?? true
        let nameRepeats = defaults.integer(forKey: Constants.prefNameRepeats)
        let speechRate = defaults.float(forKey: Constants.prefSpeechRate)
        let pitch = defaults.float(forKey: Constants.prefPitch)
        let ttsVolume = defaults.float(forKey: Constants.prefTtsVolume)
        let intervalAcceleration = defaults.object(forKey: Constants.prefIntervalAccel) as? Bool ?? true
        
        let multiplier = isSecondsMode ? 1 : 60
        timeRemainingSeconds = (totalMinutes == 0 ? 10 : totalMinutes) * multiplier
        let baseIntervalSeconds = (intervalMinutes == 0 ? 1 : intervalMinutes) * multiplier
        
        let namePhrase = speakName && !timerName.isEmpty && nameRepeats > 0 ? String(repeating: "\(timerName). ", count: nameRepeats) : ""
        let totalSpeech = TimeFormatHelper.formatTime(amount: totalMinutes == 0 ? 10 : totalMinutes, isSecondsMode: isSecondsMode)
        let intervalSpeech = TimeFormatHelper.formatTime(amount: intervalMinutes == 0 ? 1 : intervalMinutes, isSecondsMode: isSecondsMode)
        
        Task {
            await TtsManager.shared.speak(
                text: "\(namePhrase)Starting timer for \(totalSpeech), with intervals of \(intervalSpeech).",
                rate: speechRate,
                pitch: pitch,
                volume: ttsVolume,
            )
        }
        
        updateDisplays(seconds: timeRemainingSeconds, isSecondsMode: isSecondsMode, currentIntervalSeconds: baseIntervalSeconds, multiplier: multiplier)
        targetEndDate = Date().addingTimeInterval(TimeInterval(timeRemainingSeconds))
        
        targetEndDate = Date().addingTimeInterval(TimeInterval(timeRemainingSeconds))
                
        timerTask?.cancel()
        
        timerTask = Task {
            var lastEvaluatedSecond = timeRemainingSeconds
            
            while timeRemainingSeconds > 0 && !Task.isCancelled {
                if isPaused {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    targetEndDate = Date().addingTimeInterval(TimeInterval(timeRemainingSeconds))
                    continue
                }
                
                try? await Task.sleep(nanoseconds: 200_000_000)
                guard !Task.isCancelled, let target = targetEndDate else { break }
                
                let now = Date()
                let newTimeRemaining = max(0, Int(target.timeIntervalSince(now).rounded(.up)))
                
                if newTimeRemaining < lastEvaluatedSecond {
                    let rangeIntervalSeconds: Int
                    if intervalAcceleration {
                        if newTimeRemaining > 20 * multiplier {
                            rangeIntervalSeconds = baseIntervalSeconds
                        } else if newTimeRemaining > 10 * multiplier {
                            rangeIntervalSeconds = 5 * multiplier
                        } else if newTimeRemaining > 5 * multiplier {
                            rangeIntervalSeconds = 2 * multiplier
                        } else {
                            rangeIntervalSeconds = 1 * multiplier
                        }
                    } else {
                        rangeIntervalSeconds = baseIntervalSeconds
                    }
                    
                    let currentIntervalSeconds = min(baseIntervalSeconds, rangeIntervalSeconds)
                    
                    for sec in (newTimeRemaining + 1)...lastEvaluatedSecond {
                        if sec > 0 && sec % currentIntervalSeconds == 0 {
                            let timeLeftOut = sec / multiplier
                            let timeRemainingSpeech = TimeFormatHelper.formatTime(amount: timeLeftOut, isSecondsMode: isSecondsMode)
                            
                            await TtsManager.shared.speak(
                                text: "\(namePhrase)\(timeRemainingSpeech) remaining.",
                                rate: speechRate,
                                pitch: pitch,
                                volume: ttsVolume,
                            )
                        }
                    }
                    
                    timeRemainingSeconds = newTimeRemaining
                    lastEvaluatedSecond = newTimeRemaining
                    updateDisplays(seconds: timeRemainingSeconds, isSecondsMode: isSecondsMode, currentIntervalSeconds: currentIntervalSeconds, multiplier: multiplier)
                }
            }
            
            if timeRemainingSeconds <= 0 && !Task.isCancelled {
                executeCompletionSequence(timerName: timerName, nameRepeats: nameRepeats, speechRate: speechRate, pitch: pitch, ttsVolume: ttsVolume)
            }
        }
    }
    
    func stop() {
            timerTask?.cancel()
            pauseAlarmTask?.cancel()
            isRunning = false
            isPaused = false
            SilentAudioEngine.shared.stop()
            Task {
                await TtsManager.shared.stop()
            }
        NotificationCenter.default.post(name: NSNotification.Name(Constants.actionTimerFinished), object: nil)
    }
    
    func pause() {
        guard isRunning, !isPaused else { return }
        isPaused = true
        Task {
            await TtsManager.shared.stop()
        }
        startPauseAlarm()
    }
    
    func resume() {
        guard isRunning, isPaused else { return }
        isPaused = false
        pauseAlarmTask?.cancel()
        targetEndDate = Date().addingTimeInterval(TimeInterval(timeRemainingSeconds))
    }
    
    private func updateDisplays(seconds: Int, isSecondsMode: Bool, currentIntervalSeconds: Int, multiplier: Int) {
        let hours = seconds / 3600
        let mins = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            timeRemainingDisplay = String(format: "%d:%02d:%02d", hours, mins, secs)
        } else {
            timeRemainingDisplay = String(format: "%02d:%02d", mins, secs)
        }
        
        let displayInterval = currentIntervalSeconds / multiplier
        let unit = isSecondsMode ? String(localized: "unit_sec") : String(localized: "unit_min")
        currentIntervalDisplay = "\(displayInterval) \(unit)"
    }
    
    private func startPauseAlarm() {
        pauseAlarmTask?.cancel()
        
        let pauseAlarmMode = defaults.integer(forKey: Constants.prefPauseAlarmMode)
        let amount = AppConfig.pauseAlarmOptions.indices.contains(pauseAlarmMode) ? AppConfig.pauseAlarmOptions[pauseAlarmMode] : 0
        if amount == 0 { return }
        
        pauseAlarmTask = Task {
            let isSecondsMode = defaults.bool(forKey: Constants.prefIsSecondsMode)
            let delaySeconds = isSecondsMode ? amount : amount * 60
            
            while isPaused && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(delaySeconds) * 1_000_000_000)
                guard isPaused && !Task.isCancelled else { break }
                
                AudioFocusManager.setFocus()
                try? await Task.sleep(nanoseconds: 120_000_000)
                
                AudioServicesPlaySystemSound(1052)
                
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
        }
    }
    
    private func executeCompletionSequence(timerName: String, nameRepeats: Int, speechRate: Float, pitch: Float, ttsVolume: Float) {
            isRunning = false
            SilentAudioEngine.shared.stop()
            let endingPhrase = defaults.string(forKey: Constants.prefEndingPhrase) ?? String(localized: "default_ending_phrase")
        let endingRepeats = defaults.integer(forKey: Constants.prefEndingRepeats)
        
        var finalSpeech = ""
        if !timerName.isEmpty && nameRepeats > 0 {
            finalSpeech += String(repeating: "\(timerName). ", count: nameRepeats)
        }
        
        if endingRepeats > 0 {
            let safePhrase = endingPhrase.isEmpty ? String(localized: "default_ending_phrase") : endingPhrase
            finalSpeech += String(repeating: "\(safePhrase). ", count: endingRepeats)
        } else if finalSpeech.isEmpty {
            finalSpeech += String(localized: "default_ending_phrase") + "."
        }
        
        Task {
            await TtsManager.shared.speak(
                text: finalSpeech,
                rate: speechRate,
                pitch: pitch,
                volume: ttsVolume,
            )
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(Constants.actionTimerFinished), object: nil)
            }
        }
// 309 lines in v1.3
