import SwiftUI

/// Второй шаг входа: код из SMS в четырёх ячейках.
/// Настоящий ввод идёт в скрытое поле — ячейки только показывают цифры.
struct OTPEntryView: View {
    let phone: String
    let onSuccess: () -> Void

    @Environment(AuthStore.self) private var auth

    @State private var code = ""
    @State private var shakes: CGFloat = 0
    @State private var hasFailed = false
    @FocusState private var isFocused: Bool

    private static let length = 4

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.l) {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text("Код из SMS")
                    .font(DS.Typography.display)
                    .foregroundStyle(DS.Palette.textPrimary)

                Text("Отправили на \(phone)")
                    .font(DS.Typography.callout)
                    .foregroundStyle(DS.Palette.textSecondary)
            }

            cells
                .modifier(ShakeEffect(animatableData: shakes))
                .contentShape(Rectangle())
                .onTapGesture { isFocused = true }

            if hasFailed {
                Label("Неверный код", systemImage: "exclamationmark.circle")
                    .font(DS.Typography.callout)
                    .foregroundStyle(DS.Palette.accentSecondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DS.Spacing.m)
        .background(alignment: .topLeading) { hiddenField }
        .sensoryFeedback(.error, trigger: shakes)
        .task { isFocused = true }
    }

    private var cells: some View {
        HStack(spacing: DS.Spacing.s) {
            ForEach(0..<Self.length, id: \.self) { index in
                Text(verbatim: digit(at: index))
                    .font(DS.Typography.code)
                    .foregroundStyle(DS.Palette.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: DS.Size.otpCell)
                    .background(DS.Palette.surface, in: DS.Radius.shape)
                    .overlay {
                        DS.Radius.shape
                            .strokeBorder(border(at: index), lineWidth: DS.Size.hairline * 2)
                    }
            }
        }
    }

    /// Поле невидимо, но именно оно держит фокус и клавиатуру.
    /// Прячем размером и обрезкой, а не прозрачностью: значений opacity
    /// в системе ровно три, и нулю среди них места нет.
    private var hiddenField: some View {
        TextField(text: input) { EmptyView() }
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .focused($isFocused)
            .frame(width: 0, height: 0)
            .clipped()
            .accessibilityHidden(true)
    }

    private var input: Binding<String> {
        Binding(
            get: { code },
            set: { newValue in
                let digits = String(newValue.filter(\.isNumber).prefix(Self.length))
                guard digits != code else { return }
                code = digits
                hasFailed = false
                if digits.count == Self.length { verify() }
            }
        )
    }

    private func digit(at index: Int) -> String {
        guard index < code.count else { return "" }
        return String(Array(code)[index])
    }

    private func border(at index: Int) -> Color {
        if hasFailed { return DS.Palette.accentSecondary }
        return index == code.count ? DS.Palette.accent : .clear
    }

    private func verify() {
        guard auth.isValid(code: code) else {
            hasFailed = true
            code = ""
            withAnimation(.linear(duration: DS.Motion.shakeDuration)) { shakes += 1 }
            return
        }
        onSuccess()
    }
}
