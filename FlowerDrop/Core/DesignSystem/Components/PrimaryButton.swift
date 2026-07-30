import SwiftUI

/// Основное действие экрана: акцентная заливка, единый радиус,
/// spring на нажатие и haptic — по правилу «haptic на ключевые действия».
struct PrimaryButton: View {
    private let title: LocalizedStringKey
    private let systemImage: String?
    private let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled
    @State private var tapCount = 0

    init(
        _ title: LocalizedStringKey,
        systemImage: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button {
            tapCount += 1
            action()
        } label: {
            HStack(spacing: DS.Spacing.xs) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(DS.Typography.bodyEmphasized)
            .foregroundStyle(labelColor)
            .frame(maxWidth: .infinity)
            .frame(height: DS.Size.control)
            .background(fillColor, in: DS.Radius.shape)
        }
        .buttonStyle(.pressable)
        .sensoryFeedback(.impact(weight: .light), trigger: tapCount)
    }

    /// Выключенная кнопка гасит заливку, а не весь слой:
    /// подпись обязана оставаться читаемой.
    private var fillColor: Color {
        isEnabled ? DS.Palette.accent : DS.Palette.textSecondary.opacity(DS.Opacity.subtle)
    }

    private var labelColor: Color {
        isEnabled ? DS.Palette.onAccent : DS.Palette.textSecondary
    }
}

/// Единая реакция на нажатие для всех кнопок приложения.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? DS.Motion.pressedScale : 1)
            .animation(DS.Motion.spring, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}

#Preview {
    VStack(spacing: DS.Spacing.m) {
        PrimaryButton("Зарезервировать", systemImage: "bag") {}
        PrimaryButton("Разобрали") {}
            .disabled(true)
    }
    .padding(DS.Spacing.m)
    .background(DS.Palette.bg)
}
