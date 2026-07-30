import SwiftUI

/// Витрина дизайн-системы: живой чек-лист токенов и компонентов.
/// Если что-то ломается, это видно здесь раньше, чем в фичах.
struct DesignSystemPreview: View {

    private struct Swatch: Identifiable {
        let id: String
        let color: Color
    }

    private let swatches: [Swatch] = [
        Swatch(id: "bg", color: DS.Palette.bg),
        Swatch(id: "surface", color: DS.Palette.surface),
        Swatch(id: "accent", color: DS.Palette.accent),
        Swatch(id: "accentSecondary", color: DS.Palette.accentSecondary),
        Swatch(id: "onAccent", color: DS.Palette.onAccent),
        Swatch(id: "textPrimary", color: DS.Palette.textPrimary),
        Swatch(id: "textSecondary", color: DS.Palette.textSecondary)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                header
                colorsSection
                typographySection
                pricesSection
                buttonsSection
                skeletonsSection
            }
            .padding(.horizontal, DS.Spacing.m)
            .padding(.top, DS.Spacing.s)
            .padding(.bottom, DS.Spacing.xl)
        }
        .background(DS.Palette.bg)
        .scrollIndicators(.hidden)
    }

    // MARK: - Секции

    private var header: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
            Text(verbatim: "FLOWERDROP")
                .font(DS.Typography.eyebrow)
                .kerning(DS.Typography.eyebrowKerning)
                .foregroundStyle(DS.Palette.accent)

            Text("Дизайн-система")
                .font(DS.Typography.display)
                .foregroundStyle(DS.Palette.textPrimary)

            Text("Витрина токенов и компонентов")
                .font(DS.Typography.callout)
                .foregroundStyle(DS.Palette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var colorsSection: some View {
        section("Цвета") {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: DS.Size.swatchMinWidth), spacing: DS.Spacing.s)],
                spacing: DS.Spacing.s
            ) {
                ForEach(swatches) { swatch in
                    VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                        DS.Radius.shape
                            .fill(swatch.color)
                            .frame(height: DS.Size.swatch)
                            .overlay {
                                DS.Radius.shape
                                    .strokeBorder(DS.Palette.textSecondary.opacity(DS.Opacity.subtle))
                            }

                        Text(verbatim: swatch.id)
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Palette.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(DS.Typography.minimumScale)
                    }
                }
            }
            .dsCard()
        }
    }

    private var typographySection: some View {
        section("Типографика") {
            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                typeRow("Пионы и эвкалипт", font: DS.Typography.display, spec: "34 · serif semibold")
                typeRow("Букет дня", font: DS.Typography.title, spec: "22 · serif semibold")
                typeRow("Забрать сегодня до 21:00", font: DS.Typography.body, spec: "17 · SF Pro")
                typeRow("Осталось 3 букета", font: DS.Typography.callout, spec: "15 · SF Pro")
                typeRow("Цветочная лавка «Нар»", font: DS.Typography.caption, spec: "13 · SF Pro")
            }
            .dsCard()
        }
    }

    private var pricesSection: some View {
        section("Цены") {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                PriceTag(original: 60, current: 30, discountPercent: 50)
                PriceTag(original: 125.5, current: 62.75, discountPercent: 50)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .dsCard()
        }
    }

    private var buttonsSection: some View {
        section("Кнопки") {
            VStack(spacing: DS.Spacing.s) {
                PrimaryButton("Зарезервировать", systemImage: "bag") {}
                PrimaryButton("Разобрали") {}
                    .disabled(true)
            }
            .dsCard()
        }
    }

    private var skeletonsSection: some View {
        section("Скелетоны") {
            HStack(alignment: .top, spacing: DS.Spacing.s) {
                SkeletonView()
                    .aspectRatio(DS.Size.photoAspectRatio, contentMode: .fit)
                    .containerRelativeFrame(.horizontal, count: 2, span: 1, spacing: DS.Spacing.s)

                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    SkeletonView().frame(height: DS.Spacing.m)
                    SkeletonView().frame(height: DS.Spacing.s)
                    SkeletonView().frame(height: DS.Spacing.s)
                }
            }
            .dsCard()
        }
    }

    // MARK: - Строительные блоки

    private func section<Content: View>(
        _ title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            Text(title)
                .font(DS.Typography.title)
                .foregroundStyle(DS.Palette.textPrimary)
            content()
        }
    }

    private func typeRow(_ text: LocalizedStringKey, font: Font, spec: String) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
            Text(text)
                .font(font)
                .foregroundStyle(DS.Palette.textPrimary)
            Text(verbatim: spec)
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Palette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Светлая") {
    DesignSystemPreview()
}

#Preview("Тёмная") {
    DesignSystemPreview()
        .preferredColorScheme(.dark)
}
