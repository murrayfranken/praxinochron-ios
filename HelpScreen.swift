import SwiftUI

struct HelpSection: Identifiable {
    let id = UUID()
    let titleKey: String
    let itemKeys: [String]
}

struct HelpScreen: View {
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
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color.praxinoTheme.background.ignoresSafeArea())
    }
}
// 79 lines in v1.2
