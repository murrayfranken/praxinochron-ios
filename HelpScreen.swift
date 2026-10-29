import SwiftUI

struct HelpSection: Identifiable {
    let id = UUID()
    let titleKey: String
    let itemKeys: [String]
}

struct HelpScreen: View {
    @EnvironmentObject var viewModel: TimerViewModel
    @EnvironmentObject var billingManager: BillingManager
    
    @State private var showingRestoreAlert = false
    @State private var alertMessage = ""
    
    var helpContent: [HelpSection] {
        [
            HelpSection(
                titleKey: "help_title_basic_operation",
                itemKeys: [
                    "help_basic_item_1",
                    "help_basic_item_2",
                    "help_basic_item_3"
                ]
            ),
            HelpSection(
                titleKey: "help_title_managing_presets",
                itemKeys: [
                    "help_manage_item_1",
                    "help_manage_item_2",
                    "help_manage_item_3",
                    "help_manage_item_4"
                ]
            ),
            HelpSection(
                titleKey: "help_title_settings",
                itemKeys: [
                    "help_settings_item_1",
                    "help_settings_item_2",
                    "help_settings_item_3"
                ]
            )
        ]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                PraxinoCard {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(LocalizedStringKey("help_intro_text"))
                            .foregroundColor(Color.praxinoTheme.textPrimary)
                            .font(.body)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                ForEach(helpContent) { section in
                    PraxinoCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedStringKey(section.titleKey))
                                .foregroundColor(Color.praxinoTheme.textAccent)
                                .font(.title3.bold())
                                .padding(.bottom, 4)
                            
                ForEach(section.itemKeys, id: \.self) { key in
                                                Text(LocalizedStringKey(key))
                                                    .foregroundColor(Color.praxinoTheme.textPrimary)
                                                    .font(.body)
                                                    .padding(.bottom, 4)
                                            }
                                        }
                                        .padding(16)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                
                                if !viewModel.isPro {
                                    Button {
                                        Task {
                                            let success = await billingManager.restorePurchases()
                                            alertMessage = success ? String(localized: "restore_success") : String(localized: "restore_empty")
                                            showingRestoreAlert = true
                                        }
                                    } label: {
                                        Text(String(localized: "action_restore_purchases"))
                                            .font(.body)
                                            .foregroundColor(Color.praxinoTheme.appBlack)
                                            .underline()
                                            .padding(.top, 16)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 32)
                        }
                    .background(Color.praxinoTheme.background.ignoresSafeArea())
                    .alert(String(localized: "alert_restore_title"), isPresented: $showingRestoreAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text(alertMessage)
                    }
                }
            }
// 106 lines in v1.3.1 (3)
