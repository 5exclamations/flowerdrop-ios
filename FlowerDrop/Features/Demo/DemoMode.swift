import SwiftUI

/// Демо-режим: приложение показывают без сети, на встроенных данных.
///
/// Включается скрытым жестом — на витрине не должно быть кнопки «моки»,
/// но и молча подменять данные нельзя, поэтому режим обязан себя обозначать
/// бейджем в шапке.
enum DemoMode {
    /// Флаг живёт в UserDefaults через `@AppStorage`: в `@Observable`-классе
    /// он не работает (та же причина, по которой AuthStore пишет напрямую).
    static let storageKey = "demo.enabled"
    /// Свои ключи входа, чтобы демо-сессия не затирала настоящий токен.
    static let authNamespace = "demo."
    /// Столько тапов подряд включают и выключают режим.
    static let tapCount = 5
    /// Тапы засчитываются, пока пауза между ними не больше этой.
    static let tapWindow: Duration = .seconds(2)
}

/// Маленький бейдж в шапке: чтобы на показе не забыть, что данные ненастоящие.
struct DemoBadge: View {
    var body: some View {
        Text(verbatim: "DEMO")
            .font(DS.Typography.eyebrow)
            .kerning(DS.Typography.eyebrowKerning)
            .foregroundStyle(DS.Palette.onAccent)
            .padding(.horizontal, DS.Spacing.xs)
            .padding(.vertical, DS.Spacing.xxs)
            .background(DS.Palette.accentSecondary, in: DS.Radius.shape)
            .accessibilityLabel(Text("Демо-режим"))
    }
}

// MARK: - Скрытый жест

private struct SecretTapModifier: ViewModifier {
    let count: Int
    let window: Duration
    let action: () -> Void

    @State private var taps = 0
    @State private var expiry: Task<Void, Never>?
    @State private var fired = 0

    func body(content: Content) -> some View {
        content
            // Заголовок — это текст, попасть по нему пальцем можно только
            // если кликабельна вся его рамка.
            .contentShape(.rect)
            .onTapGesture(perform: register)
            .sensoryFeedback(.success, trigger: fired)
            .onDisappear {
                expiry?.cancel()
                taps = 0
            }
    }

    private func register() {
        expiry?.cancel()
        taps += 1

        guard taps < count else {
            taps = 0
            fired += 1
            action()
            return
        }

        // Серия считается прерванной, если между тапами слишком долгая пауза:
        // иначе случайные тапы за день накопятся и включат режим сами.
        expiry = Task {
            try? await Task.sleep(for: window)
            guard !Task.isCancelled else { return }
            taps = 0
        }
    }
}

extension View {
    /// Скрытый жест: `count` тапов подряд, не разваливаясь дольше `window`.
    func secretTap(
        count: Int = DemoMode.tapCount,
        within window: Duration = DemoMode.tapWindow,
        action: @escaping () -> Void
    ) -> some View {
        modifier(SecretTapModifier(count: count, window: window, action: action))
    }
}

// MARK: - Окружение

private struct IsDemoModeKey: EnvironmentKey {
    static let defaultValue = false
}

/// Переключатель режима. Живёт в окружении, чтобы шапки не тащили колбэк
/// через полдерева ради одного жеста.
struct DemoModeToggle {
    let toggle: () -> Void

    static let inactive = DemoModeToggle {}
}

private struct DemoModeToggleKey: EnvironmentKey {
    static let defaultValue = DemoModeToggle.inactive
}

extension EnvironmentValues {
    var isDemoMode: Bool {
        get { self[IsDemoModeKey.self] }
        set { self[IsDemoModeKey.self] = newValue }
    }

    var demoModeToggle: DemoModeToggle {
        get { self[DemoModeToggleKey.self] }
        set { self[DemoModeToggleKey.self] = newValue }
    }
}

#Preview {
    HStack(spacing: DS.Spacing.xs) {
        Text(verbatim: "FlowerDrop")
            .font(DS.Typography.display)
            .foregroundStyle(DS.Palette.textPrimary)
        DemoBadge()
    }
    .padding(DS.Spacing.m)
    .background(DS.Palette.bg)
}
