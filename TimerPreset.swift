import Foundation

struct TimerPreset: Codable, Identifiable, Hashable {
    var id: String { name }
    let name: String
    let totalTime: Int
    let intervalTime: Int
    let useSeconds: Bool
    let speakName: Bool
    let nameRepeats: Int
    let endingPhrase: String
    let endingRepeats: Int
    let speechRate: Float
    let pitch: Float
    let intervalAcceleration: Bool
    
    init(
        name: String,
        totalTime: Int,
        intervalTime: Int,
        useSeconds: Bool = false,
        speakName: Bool = true,
        nameRepeats: Int = 1,
        endingPhrase: String = "",
        endingRepeats: Int = 1,
        speechRate: Float = 1.0,
        pitch: Float = 1.0,
        intervalAcceleration: Bool = true
    ) {
        self.name = name
        self.totalTime = totalTime
        self.intervalTime = intervalTime
        self.useSeconds = useSeconds
        self.speakName = speakName
        self.nameRepeats = nameRepeats
        self.endingPhrase = endingPhrase
        self.endingRepeats = endingRepeats
        self.speechRate = speechRate
        self.pitch = pitch
        self.intervalAcceleration = intervalAcceleration
    }
}
