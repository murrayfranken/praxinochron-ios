import Foundation
import Combine

enum SaveResult {
    case success
    case limitReached
    case duplicateName
}

final class TimerViewModel: ObservableObject {
    private let storage: PresetStorage
    private let defaults = UserDefaults.standard
    
    @Published var savedPresets: [TimerPreset] = []
    @Published var isPro: Bool = false
    
    @Published var timerName: String
    @Published var totalTime: Int
    @Published var intervalTime: Int
    @Published var isSecondsMode: Bool
    @Published var speakName: Bool
    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false
    @Published var remainingTimeDisplay: String = ""
    @Published var currentIntervalDisplay: String = ""
    @Published var nameRepeats: Int
    @Published var endingPhrase: String
    @Published var endingRepeats: Int
    @Published var speechRate: Float
    @Published var pitch: Float
    @Published var intervalAcceleration: Bool
    
    @Published var ttsVolume: Float {
        didSet { defaults.set(ttsVolume, forKey: Constants.prefTtsVolume) }
    }
    
    @Published var pauseAlarmMode: Int {
        didSet { defaults.set(pauseAlarmMode, forKey: Constants.prefPauseAlarmMode) }
    }
    
    private var loadedTimerName: String?
    
    var isModified: Bool {
        guard let loadedName = loadedTimerName,
              let loadedPreset = savedPresets.first(where: { $0.name == loadedName }) else {
            return false
        }
        
        return timerName != loadedPreset.name ||
            totalTime != loadedPreset.totalTime ||
            intervalTime != loadedPreset.intervalTime ||
            isSecondsMode != loadedPreset.useSeconds ||
            nameRepeats != loadedPreset.nameRepeats ||
            endingPhrase != loadedPreset.endingPhrase ||
            endingRepeats != loadedPreset.endingRepeats ||
            speechRate != loadedPreset.speechRate ||
            pitch != loadedPreset.pitch ||
            intervalAcceleration != loadedPreset.intervalAcceleration
    }
    
    init(storage: PresetStorage = PresetStorage()) {
        self.storage = storage
        self.savedPresets = storage.getPresets()
        
        self.timerName = defaults.string(forKey: Constants.prefTimerName) ?? ""
        self.totalTime = defaults.object(forKey: Constants.prefTotalTime) as? Int ?? 10
        self.intervalTime = defaults.object(forKey: Constants.prefIntervalTime) as? Int ?? 1
        self.isSecondsMode = defaults.bool(forKey: Constants.prefIsSecondsMode)
        self.speakName = defaults.object(forKey: Constants.prefSpeakName) as? Bool ?? true
        self.nameRepeats = defaults.object(forKey: Constants.prefNameRepeats) as? Int ?? 1
        self.endingPhrase = defaults.string(forKey: Constants.prefEndingPhrase) ?? ""
        self.endingRepeats = defaults.object(forKey: Constants.prefEndingRepeats) as? Int ?? 1
        self.speechRate = defaults.object(forKey: Constants.prefSpeechRate) as? Float ?? 1.0
        self.pitch = defaults.object(forKey: Constants.prefPitch) as? Float ?? 1.0
        self.intervalAcceleration = defaults.object(forKey: Constants.prefIntervalAccel) as? Bool ?? true
        self.ttsVolume = defaults.object(forKey: Constants.prefTtsVolume) as? Float ?? 1.0
        self.pauseAlarmMode = defaults.integer(forKey: Constants.prefPauseAlarmMode)
        
        self.loadedTimerName = defaults.string(forKey: Constants.prefTimerName)
    }
    
    func refreshPresets() {
        savedPresets = storage.getPresets()
    }
    
    func prepareNewTimer() {
        timerName = ""
        loadedTimerName = nil
    }
    
    func initializeDefaultEnding(defaultEnding: String) {
        if endingPhrase.isEmpty {
            endingPhrase = defaultEnding
        }
    }
    
    func saveCurrentState() {
        defaults.set(timerName, forKey: Constants.prefTimerName)
        defaults.set(totalTime, forKey: Constants.prefTotalTime)
        defaults.set(intervalTime, forKey: Constants.prefIntervalTime)
        defaults.set(isSecondsMode, forKey: Constants.prefIsSecondsMode)
        defaults.set(speakName, forKey: Constants.prefSpeakName)
        defaults.set(nameRepeats, forKey: Constants.prefNameRepeats)
        defaults.set(endingPhrase, forKey: Constants.prefEndingPhrase)
        defaults.set(endingRepeats, forKey: Constants.prefEndingRepeats)
        defaults.set(speechRate, forKey: Constants.prefSpeechRate)
        defaults.set(pitch, forKey: Constants.prefPitch)
        defaults.set(intervalAcceleration, forKey: Constants.prefIntervalAccel)
        defaults.set(ttsVolume, forKey: Constants.prefTtsVolume)
        defaults.set(pauseAlarmMode, forKey: Constants.prefPauseAlarmMode)
    }
    
    func savePreset(forceNew: Bool = false) -> SaveResult {
        let isUpdate = loadedTimerName != nil && !forceNew
        
        if timerName != loadedTimerName && savedPresets.contains(where: { $0.name == timerName }) {
            return .duplicateName
        }
        
        if !isUpdate && !isPro && savedPresets.count >= AppConfig.freePresetLimit {
            return .limitReached
        }
        
        let newPreset = TimerPreset(
            name: timerName,
            totalTime: totalTime,
            intervalTime: intervalTime,
            useSeconds: isSecondsMode,
            speakName: speakName,
            nameRepeats: nameRepeats,
            endingPhrase: endingPhrase,
            endingRepeats: endingRepeats,
            speechRate: speechRate,
            pitch: pitch,
            intervalAcceleration: intervalAcceleration
        )
        
        let oldName = forceNew ? nil : loadedTimerName
        storage.savePreset(preset: newPreset, oldName: oldName)
        savedPresets = storage.getPresets()
        
        loadedTimerName = timerName
        
        return .success
    }
    
    func loadPreset(preset: TimerPreset) {
        loadedTimerName = preset.name
        timerName = preset.name
        totalTime = preset.totalTime
        intervalTime = preset.intervalTime
        isSecondsMode = preset.useSeconds
        speakName = preset.speakName
        nameRepeats = preset.nameRepeats
        endingPhrase = preset.endingPhrase
        endingRepeats = preset.endingRepeats
        speechRate = preset.speechRate
        pitch = preset.pitch
        intervalAcceleration = preset.intervalAcceleration
    }
    
    func deletePreset(name: String) {
        storage.deletePreset(name: name)
        savedPresets = storage.getPresets()
        
        if loadedTimerName == name {
            prepareNewTimer()
        }
    }
    
    func setTimerRunningState(running: Bool) {
        isRunning = running
        if !running {
            isPaused = false
        }
        if running {
            let totalSeconds = totalTime * (isSecondsMode ? 1 : 60)
            let hours = totalSeconds / 3600
            let mins = (totalSeconds % 3600) / 60
            let secs = totalSeconds % 60
            
            if hours > 0 {
                remainingTimeDisplay = String(format: "%d:%02d:%02d", hours, mins, secs)
            } else {
                remainingTimeDisplay = String(format: "%02d:%02d", mins, secs)
            }
            
            currentIntervalDisplay = "\(intervalTime) \(isSecondsMode ? String(localized: "unit_sec") : String(localized: "unit_min"))"
        }
    }
    
    func setTimerPausedState(paused: Bool) {
        isPaused = paused
    }
}
// 202 lines in v1.2
