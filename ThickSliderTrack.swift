import SwiftUI

struct ThickSliderTrack: View {
    @Binding var value: Float
    let range: ClosedRange<Float>
    let trackThickness: CGFloat
    let activeTrackColor: Color
    let inactiveTrackColor: Color
    let thumbColor: Color
    
    init(value: Binding<Float>,
         range: ClosedRange<Float>,
         trackThickness: CGFloat,
         activeTrackColor: Color,
         inactiveTrackColor: Color,
         thumbColor: Color = Color.praxinoTheme.appGreen2) {
        
        self._value = value
        self.range = range
        self.trackThickness = trackThickness
        self.activeTrackColor = activeTrackColor
        self.inactiveTrackColor = inactiveTrackColor
        self.thumbColor = thumbColor
        
        // Hide native thin tracks so custom capsules show through
        UISlider.appearance().minimumTrackTintColor = .clear
        UISlider.appearance().maximumTrackTintColor = .clear
        
        // Apply your tertiary green to the native iOS thumb
        UISlider.appearance().thumbTintColor = UIColor(thumbColor)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(inactiveTrackColor)
                    .frame(height: trackThickness)
                
                let rangeSpan = Float(range.upperBound - range.lowerBound)
                let safeSpan = rangeSpan > 0 ? rangeSpan : 1.0
                let fraction = CGFloat((value - range.lowerBound) / safeSpan)
                let activeWidth = max(0, min(geometry.size.width, geometry.size.width * fraction))
                
                Capsule()
                    .fill(activeTrackColor)
                    .frame(width: activeWidth, height: trackThickness)
                
                Slider(value: $value, in: range)
            }
            .frame(height: geometry.size.height)
        }
        .frame(height: 8)
        .padding(.top, 0)
        .padding(.bottom, 0)
    }
}
