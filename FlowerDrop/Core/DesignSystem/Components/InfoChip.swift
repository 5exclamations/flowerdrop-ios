import SwiftUI

/// Спокойная плашка с фактом о букете: дедлайн, остаток, расстояние.
struct InfoChip: View {
    let systemImage: String
    let title: LocalizedStringKey
    var isAccented = false

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(DS.Typography.callout)
            .foregroundStyle(isAccented ? DS.Palette.accentSecondary : DS.Palette.textSecondary)
            .padding(.horizontal, DS.Spacing.s)
            .padding(.vertical, DS.Spacing.xs)
            .background(DS.Palette.surface, in: DS.Radius.shape)
    }
}

#Preview {
    HStack(spacing: DS.Spacing.xs) {
        InfoChip(systemImage: "clock", title: "до 21:00", isAccented: true)
        InfoChip(systemImage: "basket", title: "осталось 2")
    }
    .padding(DS.Spacing.m)
    .background(DS.Palette.bg)
}
