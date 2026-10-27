import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

struct JSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var text: String = ""
    
    init(text: String = "") {
        self.text = text
    }
    
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}

enum CurrentScreen {
    case main, settings, help
}

struct ContentView: View {
    @StateObject private var viewModel = TimerViewModel()
    @StateObject private var billingManager = BillingManager()
    @ObservedObject private var engine = TimerEngine.shared
    
    @State private var currentScreen: CurrentScreen = .main
    @State private var showMenu = false
    @State private var presetMenuExpanded = false
    @State private var showManageDialog = false
    @State private var presetToDelete: String? = nil
    @State private var showAboutDialog = false
    @State private var currentlyLoadedName: String? = nil
    
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var exportDocument = JSONDocument(text: "")
    @State private var toastMessage: String? = nil
    
    @State private var beepTask: Task<Void, Never>? = nil
    @State private var lastClickTime: Date = .distantPast

    private var totalIndex: Binding<Float> {
        Binding<Float>(
            get: { Float(AppConfig.totalTimeOptions.firstIndex(of: viewModel.totalTime) ?? 0) },
            set: {
                let idx = Int(round($0))
                if AppConfig.totalTimeOptions.indices.contains(idx) {
                    viewModel.totalTime = AppConfig.totalTimeOptions[idx]
                }
            }
        )
    }

    private var intervalIndex: Binding<Float> {
        Binding<Float>(
            get: { Float(AppConfig.intervalOptions.firstIndex(of: viewModel.intervalTime) ?? 0) },
            set: {
                let idx = Int(round($0))
                if AppConfig.intervalOptions.indices.contains(idx) {
                    viewModel.intervalTime = AppConfig.intervalOptions[idx]
                }
            }
        )
    }

    var body: some View {
        ZStack {
            Color.praxinoTheme.background.ignoresSafeArea()
            
            VStack(spacing: 16) {
                HStack {
                    HStack(spacing: 12) {
                        if currentScreen != .main {
                            Button {
                                currentScreen = .main
                            } label: {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        } else {
                            Image("rotated7_white_on_blue")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                                .cornerRadius(10)
                        }
                        
                        Text(titleForCurrentScreen())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.praxinoTheme.appBlack)
                    }
                    
                    Spacer()
                    
                    if currentScreen == .main {
                        Menu {
                            if !viewModel.isPro {
                                Button(String(localized: "menu_unlock_pro")) {
                                    Task {
                                        await billingManager.buyPro()
                                    }
                                }
                                Divider()
                            }
                            Button(String(localized: "title_settings")) {
                                currentScreen = .settings
                            }
                            .disabled(engine.isRunning)
                            
                            Button(String(localized: "menu_help")) {
                                currentScreen = .help
                            }
                            
                            Button(String(localized: "menu_about")) {
                                showAboutDialog = true
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 24))
                                .foregroundColor(Color.praxinoTheme.appBlack)
                                .rotationEffect(.degrees(90))
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                if currentScreen == .main {
                    ScrollView {
                        VStack(spacing: 16) {
                            PraxinoCard {
                                HStack(spacing: 8) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(String(localized: "label_timer_name"))
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(Color.praxinoTheme.textAccent)
                                        TextField("", text: $viewModel.timerName)
                                            .textFieldStyle(.plain)
                                            .foregroundColor(Color.praxinoTheme.textPrimary)
                                            .disabled(engine.isRunning)
                                            .onChange(of: viewModel.timerName) { newValue in
                                                if newValue.count > Constants.maxTimerNameLength {
                                                    viewModel.timerName = String(newValue.prefix(Constants.maxTimerNameLength))
                                                }
                                            }
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Color.praxinoTheme.mediumGrey, lineWidth: 1)
                                    )
                                    
                                    Menu {
                                        Button(String(localized: "menu_new_timer")) {
                                            viewModel.prepareNewTimer()
                                            currentlyLoadedName = nil
                                        }
                                        Divider()
                                        ForEach(viewModel.savedPresets) { preset in
                                            Button(String(format: String(localized: "preset_format"), preset.name, preset.totalTime, preset.intervalTime)) {
                                                viewModel.loadPreset(preset: preset)
                                                currentlyLoadedName = preset.name
                                            }
                                        }
                                        Divider()
                                        Button(String(localized: "menu_manage_timers")) {
                                            showManageDialog = true
                                        }
                                    } label: {
                                        Image(systemName: "arrowtriangle.down.fill")
                                            .foregroundColor(Color.praxinoTheme.textPrimary)
                                            .frame(width: 44, height: 44)
                                    }
                                    .tint(Color.praxinoTheme.textAccent)
                                    .disabled(engine.isRunning)
                                }
                                .padding(16)
                            }
                            
                            if !engine.isRunning {
                                HStack(spacing: 8) {
                                    Button {
                                        handleSave(forceNew: false)
                                    } label: {
                                        Text(String(localized: "btn_update"))
                                            .font(.title3.bold())
                                            .frame(maxWidth: .infinity, minHeight: 48)
                                            .background(viewModel.isModified && currentlyLoadedName != nil ? Color.praxinoTheme.surface : Color.praxinoTheme.surface.opacity(0.5))
                                            .foregroundColor(viewModel.isModified && currentlyLoadedName != nil ? Color.praxinoTheme.textPrimary : Color.praxinoTheme.textPrimary.opacity(0.5))
                                            .cornerRadius(24)
                                    }
                                    .disabled(!(viewModel.isModified && currentlyLoadedName != nil))
                                    
                                    Button {
                                        handleSave(forceNew: true)
                                    } label: {
                                        Text(String(localized: "btn_save"))
                                            .font(.title3.bold())
                                            .frame(maxWidth: .infinity, minHeight: 48)
                                            .background(!viewModel.timerName.isEmpty && viewModel.timerName != currentlyLoadedName ? Color.praxinoTheme.surface : Color.praxinoTheme.surface.opacity(0.5))
                                            .foregroundColor(!viewModel.timerName.isEmpty && viewModel.timerName != currentlyLoadedName ? Color.praxinoTheme.textPrimary : Color.praxinoTheme.textPrimary.opacity(0.5))
                                            .cornerRadius(24)
                                    }
                                    .disabled(!(!viewModel.timerName.isEmpty && viewModel.timerName != currentlyLoadedName))
                                }
                                
                                PraxinoCard {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text(String(format: String(localized: "label_total_time"), TimeFormatHelper.formatTime(amount: viewModel.totalTime, isSecondsMode: viewModel.isSecondsMode)))
                                            .foregroundColor(Color.praxinoTheme.textPrimary)
                                            .font(.body)
                                        
                                        ThickSliderTrack(
                                            value: totalIndex,
                                            range: 0...Float(max(0, AppConfig.totalTimeOptions.count - 1)),
                                            trackThickness: 8,
                                            activeTrackColor: Color.praxinoTheme.brandBlue,
                                            inactiveTrackColor: Color.praxinoTheme.trackInactive
                                        )
                                        .padding(.bottom, 16)
                                    }
                                    .padding(16)
                                }
                                
                                PraxinoCard {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text(String(format: String(localized: "label_interval"), TimeFormatHelper.formatTime(amount: viewModel.intervalTime, isSecondsMode: viewModel.isSecondsMode)))
                                            .foregroundColor(Color.praxinoTheme.textPrimary)
                                            .font(.body)
                                        
                                        ThickSliderTrack(
                                            value: intervalIndex,
                                            range: 0...Float(max(0, AppConfig.intervalOptions.count - 1)),
                                            trackThickness: 8,
                                            activeTrackColor: Color.praxinoTheme.brandBlue,
                                            inactiveTrackColor: Color.praxinoTheme.trackInactive
                                        )
                                        
                                        HStack(spacing: 8) {
                                            Spacer()
                                            
                                            Button {
                                                viewModel.isSecondsMode = true
                                            } label: {
                                                Text(String(localized: "label_seconds_chip"))
                                                    .fontWeight(viewModel.isSecondsMode ? .bold : .regular)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(viewModel.isSecondsMode ? Color.praxinoTheme.brandBlue : Color.praxinoTheme.surface)
                                                    .foregroundColor(Color.praxinoTheme.textPrimary)
                                                    .clipShape(Capsule())
                                                    .overlay(Capsule().stroke(viewModel.isSecondsMode ? Color.praxinoTheme.brandBlue : Color.praxinoTheme.mediumGrey, lineWidth: viewModel.isSecondsMode ? 2 : 1))
                                            }
                                            
                                            Button {
                                                viewModel.isSecondsMode = false
                                            } label: {
                                                Text(String(localized: "label_minutes_chip"))
                                                    .fontWeight(!viewModel.isSecondsMode ? .bold : .regular)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(!viewModel.isSecondsMode ? Color.praxinoTheme.brandBlue : Color.praxinoTheme.surface)
                                                    .foregroundColor(Color.praxinoTheme.textPrimary)
                                                    .clipShape(Capsule())
                                                    .overlay(Capsule().stroke(!viewModel.isSecondsMode ? Color.praxinoTheme.brandBlue : Color.praxinoTheme.mediumGrey, lineWidth: !viewModel.isSecondsMode ? 2 : 1))
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding(.top, 8)
                                    }
                                    .padding(16)
                                }
                                
                                PraxinoCard {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("\(String(localized: "label_voice_volume")): \(Int(viewModel.ttsVolume * Constants.volumeMultiplier))%")
                                            .foregroundColor(Color.praxinoTheme.textPrimary)
                                            .font(.body)
                                        
                                        ThickSliderTrack(
                                            value: $viewModel.ttsVolume,
                                            range: 0...1.0,
                                            trackThickness: 8,
                                            activeTrackColor: Color.praxinoTheme.brandBlue,
                                            inactiveTrackColor: Color.praxinoTheme.trackInactive
                                        )
                                        .onChange(of: viewModel.ttsVolume) { _ in playVolumeBeep() }
                                        .padding(.bottom, 24)
                                    }
                                    .padding(16)
                                }
                                
                                Button {
                                    if canClick() {
                                        viewModel.saveCurrentState()
                                        engine.start()
                                    }
                                } label: {
                                    Text(String(localized: "btn_start"))
                                        .font(.title2.bold())
                                        .frame(maxWidth: .infinity, minHeight: 56)
                                        .background(Color.praxinoTheme.surface)
                                        .foregroundColor(Color.praxinoTheme.textPrimary)
                                        .cornerRadius(28)
                                }
                                .padding(.bottom, 16)
                                
                            } else {
                                PraxinoCard {
                                    VStack(spacing: 8) {
                                        Text(engine.timeRemainingDisplay.isEmpty ? String(localized: "fallback_time_display") : engine.timeRemainingDisplay)
                                            .font(.system(size: 64, weight: .bold))
                                            .foregroundColor(Color.praxinoTheme.textPrimary)
                                        
                                        Text(String(format: String(localized: "label_interval_display"), engine.currentIntervalDisplay))
                                            .font(.title3)
                                            .foregroundColor(Color.praxinoTheme.textSecondary)
                                    }
                                    .padding(24)
                                    .frame(maxWidth: .infinity)
                                }
                                
                                PraxinoCard {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("\(String(localized: "label_voice_volume")): \(Int(viewModel.ttsVolume * Constants.volumeMultiplier))%")
                                            .foregroundColor(Color.praxinoTheme.textPrimary)
                                            .font(.body)
                                        
                                        ThickSliderTrack(
                                            value: $viewModel.ttsVolume,
                                            range: 0...1.0,
                                            trackThickness: 8,
                                            activeTrackColor: Color.praxinoTheme.brandBlue,
                                            inactiveTrackColor: Color.praxinoTheme.trackInactive
                                        )
                                        .onChange(of: viewModel.ttsVolume) { _ in playVolumeBeep() }
                                        .padding(.bottom, 24)
                                    }
                                    .padding(16)
                                }
                                
                                HStack(spacing: 16) {
                                    Button {
                                        if canClick() {
                                            engine.stop()
                                        }
                                    } label: {
                                        Text(String(localized: "btn_stop"))
                                            .font(.title2.bold())
                                            .frame(maxWidth: .infinity, minHeight: 56)
                                            .background(Color.praxinoTheme.surface)
                                            .foregroundColor(Color.praxinoTheme.textPrimary)
                                            .cornerRadius(28)
                                    }
                                    
                                    Button {
                                        if canClick() {
                                            if engine.isPaused {
                                                engine.resume()
                                            } else {
                                                engine.pause()
                                            }
                                        }
                                    } label: {
                                        Text(engine.isPaused ? String(localized: "btn_resume") : String(localized: "btn_pause"))
                                            .font(.title2.bold())
                                            .frame(maxWidth: .infinity, minHeight: 56)
                                            .background(Color.praxinoTheme.surface)
                                            .foregroundColor(Color.praxinoTheme.textPrimary)
                                            .cornerRadius(28)
                                    }
                                }
                                .padding(.bottom, 16)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                } else if currentScreen == .settings {
                    SettingsScreen(viewModel: viewModel)
                } else if currentScreen == .help {
                    HelpScreen()
                }
                
                Spacer(minLength: 0)
            }
            
            if showManageDialog {
                Color.black.opacity(0.6).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Text(String(localized: "dialog_manage_timers_title"))
                        .font(.title3.bold())
                        .foregroundColor(Color.praxinoTheme.textAccent)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider().background(Color.praxinoTheme.background)
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(viewModel.savedPresets) { preset in
                                HStack {
                                    Button {
                                        presetToDelete = preset.name
                                    } label: {
                                        Image(systemName: "trash.fill")
                                            .foregroundColor(Color.praxinoTheme.poisonPill)
                                            .padding(12)
                                    }
                                    Text(String(format: String(localized: "preset_format"), preset.name, preset.totalTime, preset.intervalTime))
                                        .foregroundColor(Color.praxinoTheme.textPrimary)
                                    Spacer()
                                }
                                Divider().background(Color.praxinoTheme.background)
                            }
                        }
                    }
                    .frame(maxHeight: 250)
                    
                    HStack {
                        Button(String(localized: "btn_import")) {
                            showManageDialog = false
                            isImporting = true
                        }
                        Spacer()
                        Button(String(localized: "btn_export")) {
                            exportDocument = JSONDocument(text: PresetStorage().exportPresetsJson() ?? "")
                            showManageDialog = false
                            isExporting = true
                        }
                        Spacer()
                        Button(String(localized: "btn_close")) {
                            showManageDialog = false
                        }
                    }
                    .foregroundColor(Color.praxinoTheme.brandBlue)
                    .font(.body.bold())
                    .padding(16)
                }
                .background(Color.praxinoTheme.surface)
                .cornerRadius(12)
                .padding(.horizontal, 24)
            }
            
            if let message = toastMessage {
                VStack {
                    Spacer()
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(20)
                        .padding(.bottom, 60)
                }
                .zIndex(100)
            }
        }
        .onAppear {
            if currentlyLoadedName == nil && viewModel.savedPresets.contains(where: { $0.name == viewModel.timerName }) {
                currentlyLoadedName = viewModel.timerName
            }
        }
        .onChange(of: billingManager.isPro) { newValue in
            viewModel.isPro = newValue
        }
        .alert(String(localized: "dialog_delete_timer_title"), isPresented: Binding(
            get: { presetToDelete != nil },
            set: { if !$0 { presetToDelete = nil } }
        )) {
            Button(String(localized: "btn_yes"), role: .destructive) {
                if let name = presetToDelete {
                    viewModel.deletePreset(name: name)
                    presetToDelete = nil
                }
            }
            Button(String(localized: "btn_no"), role: .cancel) {
                presetToDelete = nil
            }
        } message: {
            if let name = presetToDelete {
                Text(String(format: String(localized: "dialog_delete_timer_text"), name))
            }
        }
        .overlay {
            if showAboutDialog {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture { showAboutDialog = false }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text(String(localized: "menu_about"))
                            .font(.headline)
                            .foregroundColor(Color.praxinoTheme.textPrimary)
                        
                        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? String(localized: "fallback_version_name")
                        Text("\(String(localized: "about_text_copyright"))v\(version)\n\n\(String(localized: "about_text_resources"))")
                            .font(.subheadline)
                            .foregroundColor(Color.praxinoTheme.textSecondary)
                        
                        if let url = URL(string: Constants.urlPraxinoscope) {
                            Link(Constants.urlPraxinoscope, destination: url)
                                .font(.subheadline)
                                .foregroundColor(Color.praxinoTheme.brandBlue)
                        }
                        
                        HStack {
                            Spacer()
                            Button(String(localized: "btn_ok")) {
                                showAboutDialog = false
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.praxinoTheme.brandBlue)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(20)
                    .background(Color.praxinoTheme.surface)
                    .cornerRadius(16)
                    .shadow(radius: 10)
                    .padding(.horizontal, 40)
                }
            }
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .json,
            defaultFilename: String(localized: "default_export_filename")
        ) { result in
            switch result {
            case .success:
                showToast(String(localized: "msg_export_success"))
            case .failure:
                break
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json]
        ) { result in
            switch result {
            case .success(let url):
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let data = try? Data(contentsOf: url),
                       let json = String(data: data, encoding: .utf8),
                       PresetStorage().importPresetsJson(jsonString: json) {
                        viewModel.refreshPresets()
                        showToast(String(localized: "msg_import_success"))
                    } else {
                        showToast(String(localized: "msg_import_fail"))
                    }
                }
            case .failure:
                showToast(String(localized: "msg_import_fail"))
            }
        }
    }
    
    private func titleForCurrentScreen() -> String {
        switch currentScreen {
        case .settings: return String(localized: "title_settings")
        case .help: return String(localized: "menu_help")
        case .main: return String(localized: "title_main")
        }
    }
    
    private func handleSave(forceNew: Bool) {
        if forceNew {
            let result = viewModel.savePreset(forceNew: true)
            handleSaveResult(result, isUpdate: false)
        } else {
            let isDuplicate = viewModel.timerName != currentlyLoadedName && viewModel.savedPresets.contains(where: { $0.name == viewModel.timerName })
            if isDuplicate {
                showToast(String(localized: "error_duplicate_name"))
            } else {
                let result = viewModel.savePreset(forceNew: false)
                handleSaveResult(result, isUpdate: true)
            }
        }
    }
    
    private func handleSaveResult(_ result: SaveResult, isUpdate: Bool) {
        switch result {
        case .success:
            showToast(isUpdate ? String(localized: "msg_updated") : String(localized: "msg_saved"))
            currentlyLoadedName = viewModel.timerName
        case .limitReached:
            showToast(String(format: String(localized: "error_preset_limit"), AppConfig.freePresetLimit))
        case .duplicateName:
            showToast(String(localized: "error_duplicate_name"))
        }
    }
    
    private func canClick() -> Bool {
        let now = Date()
        if now.timeIntervalSince(lastClickTime) < (Double(Constants.clickDebounceMs) / 1000.0) {
            return false
        }
        lastClickTime = now
        return true
    }
    
    private func playVolumeBeep() {
            beepTask?.cancel()
            beepTask = Task {
                try? await Task.sleep(nanoseconds: 200_000_000)
                guard !Task.isCancelled else { return }
                
                await TtsManager.shared.stop()
                let defaultName = String(localized: "default_timer_name_voice", defaultValue: "Timer")
                let text = viewModel.timerName.isEmpty ? defaultName : viewModel.timerName
                await TtsManager.shared.speak(
                    text: text,
                    rate: viewModel.speechRate,
                    pitch: viewModel.pitch,
                    volume: viewModel.ttsVolume,
                )
            }
        }
    
    private func showToast(_ message: String) {
        toastMessage = message
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if toastMessage == message {
                toastMessage = nil
            }
        }
    }
}
// 652 lines in v1.2
