import Foundation

enum TimeFormatHelper {
    static func formatTime(amount: Int, isSecondsMode: Bool) -> String {
        if amount < 60 {
            let unitKey = isSecondsMode ? "unit_seconds" : "unit_minutes"
            let fallback = isSecondsMode ? (amount == 1 ? "second" : "seconds") : (amount == 1 ? "minute" : "minutes")
            let unit = getSafeUnit(key: unitKey, amount: amount, fallback: fallback)
            return "\(amount) \(unit)"
        }
        
        let high = amount / 60
        let low = amount % 60
        
        let highKey = isSecondsMode ? "unit_minutes" : "unit_hours"
        let highFallback = isSecondsMode ? (high == 1 ? "minute" : "minutes") : (high == 1 ? "hour" : "hours")
        let highUnit = getSafeUnit(key: highKey, amount: high, fallback: highFallback)
        
        if low == 0 {
            return "\(high) \(highUnit)"
        }
        
        let lowKey = isSecondsMode ? "unit_seconds" : "unit_minutes"
        let lowFallback = isSecondsMode ? (low == 1 ? "second" : "seconds") : (low == 1 ? "minute" : "minutes")
        let lowUnit = getSafeUnit(key: lowKey, amount: low, fallback: lowFallback)
        
        return "\(high) \(highUnit), \(low) \(lowUnit)"
    }
    
    private static func getSafeUnit(key: String, amount: Int, fallback: String) -> String {
        let formatStr = NSLocalizedString(key, comment: "")
        
        // Try native 64-bit formatting
        var formatted = String.localizedStringWithFormat(formatStr, amount)
        
        // If Apple's engine fails, try 32-bit C-vararg formatting
        if formatted.contains("%#@") || formatted.contains("(null)") {
            formatted = String.localizedStringWithFormat(formatStr, Int32(amount))
            
            // If the .stringsdict is completely broken, fallback to native Swift English
            if formatted.contains("%#@") || formatted.contains("(null)") {
                return fallback
            }
        }
        
        return formatted
    }
}
