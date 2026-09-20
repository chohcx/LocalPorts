import SwiftUI

/// Interaction-only animations; refreshing process metrics never animates the row.
struct ActionFeedbackStyle: ButtonStyle {
    let destructive: Bool
    func makeBody(configuration: Configuration) -> some View {
        Feedback(configuration: configuration, destructive: destructive)
    }
    private struct Feedback: View {
        let configuration: ButtonStyle.Configuration
        let destructive: Bool
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @Environment(\.isEnabled) private var isEnabled
        @State private var hovered = false
        var body: some View {
            configuration.label
                .background(Color.black
                    .opacity(isEnabled && configuration.isPressed ? 0.38 : (isEnabled && hovered ? 0.24 : 0.08)),
                    in: RoundedRectangle(cornerRadius: 5))
                .scaleEffect(reduceMotion || !isEnabled ? 1 : (configuration.isPressed ? 0.96 : (hovered ? 1.03 : 1)))
                .opacity(isEnabled ? 1 : 0.45)
                .onHover { hovered = $0 }
                .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: hovered)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }
}
