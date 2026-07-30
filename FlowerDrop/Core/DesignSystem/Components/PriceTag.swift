import SwiftUI

/// Цена букета: старая зачёркнута, новая крупная, рядом бейдж со скидкой.
/// Процент считается из цен, а не передаётся руками.
struct PriceTag: View {
    let original: Decimal
    let current: Decimal

    private var discountPercent: Int {
        guard original > 0, current < original else { return 0 }
        let ratio = (original - current) / original
        return Int((NSDecimalNumber(decimal: ratio).doubleValue * 100).rounded())
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.xs) {
            Text(verbatim: DS.Format.price(original))
                .font(DS.Typography.priceStruck)
                .strikethrough()
                .foregroundStyle(DS.Palette.textSecondary)

            Text(verbatim: DS.Format.price(current))
                .font(DS.Typography.price)
                .foregroundStyle(DS.Palette.textPrimary)

            if discountPercent > 0 {
                DiscountBadge(percent: discountPercent)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Бейдж скидки. Терракота — вторичный акцент, только для скидок и дедлайнов.
struct DiscountBadge: View {
    let percent: Int

    var body: some View {
        Text(verbatim: "−\(percent)%")
            .font(DS.Typography.badge)
            .foregroundStyle(DS.Palette.onAccent)
            .padding(.horizontal, DS.Spacing.xs)
            .padding(.vertical, DS.Spacing.xxs)
            .background(DS.Palette.accentSecondary, in: DS.Radius.shape)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: DS.Spacing.m) {
        PriceTag(original: 60, current: 30)
        PriceTag(original: 125.5, current: 62.75)
    }
    .padding(DS.Spacing.m)
    .background(DS.Palette.bg)
}
