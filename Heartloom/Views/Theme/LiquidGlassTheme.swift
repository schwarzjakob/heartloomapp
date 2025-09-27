import SwiftUI

struct LiquidGlassBackground: View {
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            LinearGradient(colors: [.black.opacity(0.85), Color(red: 0.05, green: 0.09, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .overlay(
                    RadialGradient(colors: [Color(red: 0.24, green: 0.38, blue: 0.9).opacity(0.45), .clear], center: .topTrailing, startRadius: 40, endRadius: max(size.width, size.height))
                        .blendMode(.plusLighter)
                )
                .overlay(
                    AngularGradient(colors: [Color(red: 0.8, green: 0.36, blue: 0.88).opacity(0.25), .clear, Color(red: 0.3, green: 0.9, blue: 0.95).opacity(0.3), .clear], center: .center)
                        .rotationEffect(.degrees(25))
                )
                .ignoresSafeArea()
        }
    }
}

struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let padding: CGFloat
    let content: Content

    init(cornerRadius: CGFloat = 28, padding: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(LinearGradient(colors: [Color.white.opacity(0.18), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(LinearGradient(colors: [Color.white.opacity(0.35), Color.white.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.9)
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 18, y: 10)
            }
    }
}

struct GlassChip: ViewModifier {
    var cornerRadius: CGFloat = 18
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(LinearGradient(colors: [Color.white.opacity(0.14), Color.white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).stroke(Color.white.opacity(0.28)))
            )
    }
}

struct GlassTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LinearGradient(colors: [Color.white.opacity(0.16), Color.white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.24))
                    )
            )
            .foregroundStyle(.primary)
    }
}

struct GlassButtonStyle: ButtonStyle {
    var tint: LinearGradient = LinearGradient(colors: [Color(red: 0.3, green: 0.8, blue: 0.9), Color(red: 0.78, green: 0.42, blue: 0.95)], startPoint: .topLeading, endPoint: .bottomTrailing)

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(tint)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.35))
                    )
                    .shadow(color: Color(red: 0.2, green: 0.6, blue: 0.9).opacity(configuration.isPressed ? 0.2 : 0.35), radius: 20, y: 12)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension View {
    func glassChip(cornerRadius: CGFloat = 18) -> some View {
        modifier(GlassChip(cornerRadius: cornerRadius))
    }

    func glassCardStyle(cornerRadius: CGFloat = 28, padding: CGFloat = 20) -> some View {
        GlassCard(cornerRadius: cornerRadius, padding: padding) { self }
    }
}

extension TextFieldStyle where Self == GlassTextFieldStyle {
    static var glass: GlassTextFieldStyle { GlassTextFieldStyle() }
}
