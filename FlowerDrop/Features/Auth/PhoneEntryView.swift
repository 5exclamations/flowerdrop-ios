import SwiftUI

/// Первый шаг входа: номер телефона с маской под азербайджанский формат.
///
/// Ввод держит скрытое поле, а маску рисуем сами. Обратная запись
/// отформатированной строки в `TextField` теряла цифры при быстром наборе.
struct PhoneEntryView: View {
    @Binding var digits: String
    let isBusy: Bool
    let error: LocalizedStringKey?
    let onContinue: () -> Void

    @FocusState private var isFocused: Bool

    private var isComplete: Bool {
        digits.count == AuthStore.phoneLength
    }

    private var input: Binding<String> {
        Binding(
            get: { digits },
            set: { digits = String($0.filter(\.isNumber).prefix(AuthStore.phoneLength)) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.l) {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text("Вход по номеру")
                    .font(DS.Typography.display)
                    .foregroundStyle(DS.Palette.textPrimary)

                Text("Пришлём код в SMS — он нужен, чтобы держать резерв за вами.")
                    .font(DS.Typography.callout)
                    .foregroundStyle(DS.Palette.textSecondary)
            }

            field

            if let error {
                Label(error, systemImage: "exclamationmark.circle")
                    .font(DS.Typography.callout)
                    .foregroundStyle(DS.Palette.accentSecondary)
            }

            PrimaryButton("Получить код", systemImage: "arrow.right", action: onContinue)
                .disabled(!isComplete || isBusy)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DS.Spacing.m)
        .background(alignment: .topLeading) { hiddenField }
        .task { isFocused = true }
    }

    private var field: some View {
        HStack(spacing: DS.Spacing.s) {
            Text(verbatim: AuthStore.countryCode)
                .foregroundStyle(DS.Palette.textSecondary)

            if digits.isEmpty {
                Text(verbatim: "XX XXX XX XX")
                    .foregroundStyle(DS.Palette.textSecondary.opacity(DS.Opacity.strong))
            } else {
                Text(verbatim: AuthStore.mask(digits))
                    .foregroundStyle(DS.Palette.textPrimary)
            }

            Spacer(minLength: 0)
        }
        .font(DS.Typography.priceCompact)
        .padding(DS.Spacing.m)
        .frame(minHeight: DS.Size.control)
        .background(DS.Palette.surface, in: DS.Radius.shape)
        .overlay {
            DS.Radius.shape
                .strokeBorder(
                    isFocused ? DS.Palette.accent : .clear,
                    lineWidth: DS.Size.hairline * 2
                )
        }
        .contentShape(DS.Radius.shape)
        .onTapGesture { isFocused = true }
    }

    /// Поле невидимо, но именно оно держит фокус и клавиатуру.
    /// Прячем размером и обрезкой, а не прозрачностью: значений opacity
    /// в системе ровно три, и нулю среди них места нет.
    private var hiddenField: some View {
        TextField(text: input) { EmptyView() }
            .keyboardType(.numberPad)
            .textContentType(.telephoneNumber)
            .focused($isFocused)
            .frame(width: 0, height: 0)
            .clipped()
            .accessibilityHidden(true)
    }
}
