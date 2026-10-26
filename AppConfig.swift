import Foundation

enum AppConfig {
    static let totalTimeOptions: [Int] = Array(1...60) + [70, 80, 90, 100, 110, 120, 150, 180, 210, 240, 270, 300, 330, 360, 390, 420, 450, 480]
    static let intervalOptions: [Int] = Array(1...60)
    static let pauseAlarmOptions: [Int] = [0, 1, 2, 3]
    static var enablePauseAlarmBuzzing: Bool = false
    static let freePresetLimit: Int = 3
}
