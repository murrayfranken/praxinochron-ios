import Foundation
import os

struct PresetExport: Codable {
    let schemaVersion: Int
    let presets: [TimerPreset]
}

class PresetStorage {
    private let defaults: UserDefaults
    private let logger = Logger(subsystem: Constants.logTagTimer, category: "PresetStorage")
    
    init(suiteName: String? = Constants.prefsPresets) {
        self.defaults = UserDefaults(suiteName: suiteName) ?? .standard
    }
    
    func getPresets() -> [TimerPreset] {
        guard let data = defaults.data(forKey: Constants.prefPresetsArray) else { return [] }
        
        do {
            let presets = try JSONDecoder().decode([TimerPreset].self, from: data)
            return presets.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            logger.error("Failed to decode presets: \(error.localizedDescription)")
            return []
        }
    }
    
    func savePreset(preset: TimerPreset, oldName: String? = nil) {
        var current = getPresets()
        let searchName = oldName ?? preset.name
        
        if let index = current.firstIndex(where: { $0.name == searchName }) {
            current[index] = preset
        } else {
            current.append(preset)
        }
        saveAll(list: current)
    }
    
    func deletePreset(name: String) {
        var current = getPresets()
        current.removeAll { $0.name == name }
        saveAll(list: current)
    }
    
    private func saveAll(list: [TimerPreset]) {
        do {
            let data = try JSONEncoder().encode(list)
            defaults.set(data, forKey: Constants.prefPresetsArray)
        } catch {
            logger.error("Failed to encode presets: \(error.localizedDescription)")
        }
    }
    
    func exportPresetsJson() -> String? {
        let presets = getPresets()
        let export = PresetExport(schemaVersion: Constants.jsonValSchemaVersion, presets: presets)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(export)
            return String(data: data, encoding: .utf8)
        } catch {
            logger.error("Failed to export presets to JSON: \(error.localizedDescription)")
            return nil
        }
    }
    
    func importPresetsJson(jsonString: String) -> Bool {
        guard let data = jsonString.data(using: .utf8) else { return false }
        
        do {
                    let decoder = JSONDecoder()
                    let importedPresets: [TimerPreset]
                    
                    if let exportWrapper = try? decoder.decode(PresetExport.self, from: data) {
                        importedPresets = exportWrapper.presets
                    } else {
                        importedPresets = try decoder.decode([TimerPreset].self, from: data)
                    }
            
            var current = getPresets()
            
            for newPreset in importedPresets {
                if let index = current.firstIndex(where: { $0.name == newPreset.name }) {
                    current[index] = newPreset
                } else {
                    current.append(newPreset)
                }
            }
            
            saveAll(list: current)
            return true
            
        } catch {
            logger.error("Failed to decode imported JSON: \(error.localizedDescription)")
            return false
        }
    }
}
