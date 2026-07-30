import SwiftUI

/// Цена букета: старая зачёркнута, новая крупная, рядом бейдж со скидкой.
/// Процент приходит с сервера — клиент его не пересчитывает.
struct PriceTag: View {
    let original: Decimal
    let current: Decimal
    let discountPercent: Int

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
        PriceTag(original: 60, current: 30, discountPercent: 50)
        PriceTag(original: 125.5, current: 62.75, discountPercent: 50)
    }
    .padding(DS.Spacing.m)
    .background(DS.Palette.bg)
}
