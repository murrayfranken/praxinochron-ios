import SwiftUI
import AVFoundation

struct SettingsScreen: View {
    @ObservedObject var viewModel: TimerViewModel
    
    @State private var previewTask: Task<Void, Never>? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                PraxinoCard {
                    VStack(spacing: 16) {
                        Toggle(isOn: $viewModel.speakName) {
                            (Text(NSLocalizedString("label_speak_name", comment: "") + ": ").font(.title3) +
                             Text(viewModel.timerName.isEmpty ? NSLocalizedString("label_default_timer_name", comment: "") : viewModel.timerName).font(.title3.bold()))
                            .foregroundColor(Color.praxinoTheme.textPrimary)
                        }
                        .tint(Color.praxinoTheme.brandBlue)
                        
                        Toggle(isOn: $viewModel.intervalAcceleration) {
                            Text(NSLocalizedString("label_interval_acceleration", comment: ""))
                                .font(.body)
                                .foregroundColor(Color.praxinoTheme.textPrimary)
                        }
                        .tint(Color.praxinoTheme.brandBlue)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                
                PraxinoCard {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(NSLocalizedString("label_ending_phrase", comment: ""))
                                .font(.subheadline.bold())
                                .foregroundColor(Color.praxinoTheme.textAccent)
                            
                            TextField("", text: $viewModel.endingPhrase)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: viewModel.endingPhrase) { newValue in
                                    if newValue.count > Constants.maxPhraseLength {
                                        viewModel.endingPhrase = String(newValue.prefix(Constants.maxPhraseLength))
                                    }
                                }
                        }
                        
                        HStack {
                            Text(NSLocalizedString("label_repeat_ending", comment: ""))
                                .font(.body)
                                .foregroundColor(Color.praxinoTheme.textPrimary)
                            
                            Spacer()
                            
                            Menu {
                                ForEach(0...Constants.maxEndingRepeats, id: \.self) { count in
                                    Button {
                                        viewModel.endingRepeats = count
                                        if count > 0 {
                                            let safePhrase = viewModel.endingPhrase.isEmpty ? NSLocalizedString("default_ending_phrase", comment: "") : viewModel.endingPhrase
                                            let previewText = String(repeating: "\(safePhrase). ", count: count)
                                            Task {
                                                await TtsManager.shared.stop()
                                                await TtsManager.shared.speak(
                                                    text: previewText,
                                                    rate: viewModel.speechRate,
                                                    pitch: viewModel.pitch,
                                                    volume: viewModel.ttsVolume,
                                                )
                                            }
                                        }
                                    } label: {
                                        Text(count == 0 ? NSLocalizedString("label_off", comment: "") : String(format: NSLocalizedString("label_repeats_format", comment: ""), count))
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(viewModel.endingRepeats == 0 ? NSLocalizedString("label_off", comment: "") : String(format: NSLocalizedString("label_repeats_format", comment: ""), viewModel.endingRepeats))
                                        .font(.body)
                                        .foregroundColor(Color.praxinoTheme.textPrimary)
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(Color.praxinoTheme.brandBlue)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
                
                PraxinoCard {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 20) {
                            Text(NSLocalizedString("label_voice_speed", comment: ""))
                                .font(.body)
                                .foregroundColor(Color.praxinoTheme.textPrimary)
                            
                            ThickSliderTrack(
                                value: $viewModel.speechRate,
                                range: Constants.voiceRateMin...Constants.voiceRateMax,
                                trackThickness: 8,
                                activeTrackColor: Color.praxinoTheme.brandBlue,
                                inactiveTrackColor: Color.praxinoTheme.mediumGrey
                            )
                            .tint(Color.praxinoTheme.appGreen2)
                            .onChange(of: viewModel.speechRate) { _ in previewTTSDebounced() }
                        }
                        
                        VStack(alignment: .leading, spacing: 20) {
                            Text(NSLocalizedString("label_voice_pitch", comment: ""))
                                .font(.body)
                                .foregroundColor(Color.praxinoTheme.textPrimary)
                            
                            ThickSliderTrack(
                                value: $viewModel.pitch,
                                range: Constants.voicePitchMin...Constants.voicePitchMax,
                                trackThickness: 8,
                                activeTrackColor: Color.praxinoTheme.brandBlue,
                                inactiveTrackColor: Color.praxinoTheme.mediumGrey
                            )
                            .tint(Color.praxinoTheme.appGreen2)
                            .onChange(of: viewModel.pitch) { _ in previewTTSDebounced() }
                            .padding(.bottom, 16)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
                
                PraxinoCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(NSLocalizedString("label_audio_pause_alarm", comment: ""))
                            .font(.body)
                            .foregroundColor(Color.praxinoTheme.textPrimary)
                        
                        Picker("", selection: $viewModel.pauseAlarmMode) {
                            ForEach(AppConfig.pauseAlarmOptions.indices, id: \.self) { index in
                                let amount = AppConfig.pauseAlarmOptions[index]
                                if amount == 0 {
                                    Text(NSLocalizedString("label_off", comment: "")).tag(index)
                                } else {
                                    if viewModel.isSecondsMode {
                                        Text(String(format: NSLocalizedString("label_audio_sec_short", comment: ""), amount)).tag(index)
                                    } else {
                                        Text(String(format: NSLocalizedString("label_audio_min_short", comment: ""), amount)).tag(index)
                                    }
                                }
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color.praxinoTheme.background.ignoresSafeArea())
    }
    
    private func previewTTSDebounced() {
        previewTask?.cancel()
        previewTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            
            await TtsManager.shared.stop()
            let defaultName = NSLocalizedString("default_timer_name_voice", comment: "")
            let text = viewModel.timerName.isEmpty ? defaultName : viewModel.timerName
            await TtsManager.shared.speak(
                text: text,
                rate: viewModel.speechRate,
                pitch: viewModel.pitch,
                volume: viewModel.ttsVolume,
            )
        }
    }
}
// 181 lines in v1.3
