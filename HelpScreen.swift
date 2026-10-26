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
                    String(localized: "help_settings_item_3"),
                    String(localized: "help_settings_item_4")
                ]
            )
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(String(localized: "help_intro_text"))
                        .foregroundColor(Color.praxinoTheme.textPrimary)
                        .font(.body)
                        .padding(.bottom, 24)
                    
                    ForEach(helpContent) { section in
                        Text(section.title)
                            .foregroundColor(Color.praxinoTheme.appGreen)
                            .fontWeight(.bold)
                            .font(.body)
                            .padding(.bottom, 8)
                        
                        ForEach(section.items, id: \.self) { item in
                            Text(item)
                                .foregroundColor(Color.praxinoTheme.textPrimary)
                                .font(.body)
                                .padding(.bottom, 12)
                        }
                        
                        Spacer()
                            .frame(height: 16)
                    }
                }
                .padding(16)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.praxinoTheme.surface)
        .cornerRadius(12)
        .padding(.bottom, 16)
    }
}
// 77 lines in v1.1
