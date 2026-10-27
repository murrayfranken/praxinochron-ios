import SwiftUI

struct HelpSection: Identifiable {
    let id = UUID()
    let title: String
    let items: [String]
}

struct HelpScreen: View {
    var helpContent: [HelpSection] {
        [
            HelpSection(
                title: String(localized: "help_title_basic_operation"),
                items: [
                    String(localized: "help_basic_item_1"),
                    String(localized: "help_basic_item_2"),
                    String(localized: "help_basic_item_3")
                ]
            ),
            HelpSection(
                title: String(localized: "help_title_managing_presets"),
                items: [
                    String(localized: "help_manage_item_1"),
                    String(localized: "help_manage_item_2"),
                    String(localized: "help_manage_item_3"),
                    String(localized: "help_manage_item_4")
                ]
            ),
            HelpSection(
                title: String(localized: "help_title_settings"),
                items: [
                    String(localized: "help_settings_item_1"),
                    String(localized: "help_settings_item_2"),
                    String(localized: "help_settings_item_3")
                ]
            )
        ]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                PraxinoCard {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(String(localized: "help_intro_text"))
                            .foregroundColor(Color.praxinoTheme.textPrimary)
                            .font(.body)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                ForEach(helpContent) { section in
                    PraxinoCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(section.title)
                                .foregroundColor(Color.praxinoTheme.textAccent)
                                .font(.title3.bold())
                                .padding(.bottom, 4)
                            
                            ForEach(section.items, id: \.self) { item in
                                Text(item)
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
            .padding(16)
        }
        .background(Color.praxinoTheme.background.ignoresSafeArea())
    }
}
// 76 lines in v1.2
