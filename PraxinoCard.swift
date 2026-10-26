import SwiftUI

struct PraxinoCard<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity)
        .background(Color.praxinoTheme.surface)
        .cornerRadius(12)
    }
}
