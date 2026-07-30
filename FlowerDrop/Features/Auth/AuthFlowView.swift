import SwiftUI

/// Вход в два шага: номер, затем код. Показываем при первой попытке
/// зарезервировать букет. Код проверяет сервер (в dev это всегда 1111).
struct AuthFlowView: View {
    @Environment(AuthStore.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var step: Step = .phone
    @State private var digits = ""
    @State private var isBusy = false
    @State private var phoneError: LocalizedStringKey?

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
            PhoneEntryView(digits: $digits, isBusy: isBusy, error: phoneError) {
                Task { await requestCode() }
            }
            .transition(.move(edge: .leading).combined(with: .opacity))

        case .code:
            OTPEntryView(phone: "\(AuthStore.countryCode) \(AuthStore.mask(digits))") {
                dismiss()
            }
            .transition(.move(edge: .trailing).combined(with: .opacity))
        }
    }

    private func requestCode() async {
        isBusy = true
        phoneError = nil
        defer { isBusy = false }

        do {
            try await auth.requestCode(phoneDigits: digits)
            withAnimation(DS.Motion.spring) { step = .code }
        } catch let error as APIError {
            phoneError = Self.message(for: error)
        } catch {
            phoneError = "Не удалось отправить код"
        }
    }

    private static func message(for error: APIError) -> LocalizedStringKey {
        switch error {
        case .otpCooldown, .throttled: "Слишком часто. Подожди минуту."
        case .validation: "Проверь номер."
        case .unreachable: "Нет связи с сервером."
        default: "Не удалось отправить код"
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
