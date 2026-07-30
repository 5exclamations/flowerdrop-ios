import SwiftUI

/// Вход в два шага: номер, затем код. Показываем при первой попытке
/// зарезервировать букет.
struct AuthFlowView: View {
    @Environment(AuthStore.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var step: Step = .phone
    @State private var digits = ""

    private enum Step {
        case phone
        case code
    }

    var body: some View {
        ZStack {
            DS.Palette.bg
                .ignoresSafeArea()

            // Кнопка закрытия — отдельной строкой, а не оверлеем:
            // так заголовок стартует на той же высоте, что на остальных экранах.
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                HStack {
                    Spacer(minLength: 0)
                    closeButton
                }
                .padding(.horizontal, DS.Spacing.m)

                content
            }
            .padding(.top, DS.Spacing.xs)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .phone:
            PhoneEntryView(digits: $digits) {
                withAnimation(DS.Motion.spring) { step = .code }
            }
            .transition(.move(edge: .leading).combined(with: .opacity))

        case .code:
            OTPEntryView(phone: "\(AuthStore.countryCode) \(AuthStore.mask(digits))") {
                auth.signIn(phoneDigits: digits)
                dismiss()
            }
            .transition(.move(edge: .trailing).combined(with: .opacity))
        }
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(DS.Typography.bodyEmphasized)
                .foregroundStyle(DS.Palette.textSecondary)
                .frame(width: DS.Size.minTapTarget, height: DS.Size.minTapTarget)
                .background(DS.Palette.surface, in: DS.Radius.shape)
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("Закрыть")
    }
}
