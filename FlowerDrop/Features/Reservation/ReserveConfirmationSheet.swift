import SwiftUI

/// Подтверждение резерва: что берём, где забирать и сколько держится бронь.
struct ReserveConfirmationSheet: View {
    let bouquet: Bouquet
    let isBusy: Bool
    let onConfirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.l) {
            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                Text("Резерв букета")
                    .font(DS.Typography.title)
                    .foregroundStyle(DS.Palette.textPrimary)

                Text(bouquet.title)
                    .font(DS.Typography.callout)
                    .foregroundStyle(DS.Palette.textSecondary)
            }

            VStack(spacing: DS.Spacing.s) {
                SummaryRow(title: "Итого") {
                    Text(verbatim: DS.Format.price(bouquet.discountedPrice))
                        .font(DS.Typography.priceCompact)
                        .foregroundStyle(DS.Palette.textPrimary)
                }

                hairline

                SummaryRow(title: "Забрать до") {
                    Text(verbatim: bouquet.pickupUntilText)
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Palette.textPrimary)
                }

                hairline

                SummaryRow(title: "Адрес") {
                    Text(verbatim: "\(bouquet.shopName), \(bouquet.shopAddress)")
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Palette.textPrimary)
                        .multilineTextAlignment(.trailing)
                }
            }
            .dsCard()

            Label("Резерв держится 2 часа", systemImage: "hourglass")
                .font(DS.Typography.callout)
                .foregroundStyle(DS.Palette.accentSecondary)

            PrimaryButton("Подтвердить резерв", systemImage: "checkmark", action: onConfirm)
                .disabled(isBusy)
        }
        .padding(DS.Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(DS.Palette.bg)
    }

    private var hairline: some View {
        Rectangle()
            .fill(DS.Palette.textSecondary.opacity(DS.Opacity.subtle))
            .frame(height: DS.Size.hairline)
    }
}

/// Строка сводки: подпись слева, значение справа.
private struct SummaryRow<Value: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder var value: () -> Value

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.m) {
            Text(title)
                .font(DS.Typography.callout)
                .foregroundStyle(DS.Palette.textSecondary)

            Spacer(minLength: DS.Spacing.xs)

            value()
        }
    }
}
