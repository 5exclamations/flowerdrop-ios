import SwiftUI

/// Единственный экран знакомства: показывается один раз, до ленты.
/// Ни одного нового цвета или шрифта — всё из дизайн-системы.
struct OnboardingView: View {
    let onContinue: () -> Void

    @Environment(\.isDemoMode) private var isDemoMode
    @Environment(\.demoModeToggle) private var demoModeToggle

    private struct Point: Identifiable {
        let id: String
        let systemImage: String
        let text: LocalizedStringKey
    }

    private let points: [Point] = [
        Point(id: "discount", systemImage: "tag", text: "Скидка −50% на то, что не разобрали вчера"),
        Point(id: "reserve", systemImage: "bolt", text: "Резерв за минуту — код придёт сразу"),
        Point(id: "pickup", systemImage: "clock", text: "Забрать сегодня, до закрытия лавки")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.l) {
            Spacer(minLength: DS.Spacing.xl)

            // Бейдж стоит у знака, а не у заголовка: рядом с заголовком он
            // отнимает ширину и ломает его на две строки.
            HStack(spacing: DS.Spacing.s) {
                Image("LaunchMark")
                    .resizable()
                    .scaledToFit()
                    .frame(height: DS.Size.onboardingMark)
                    .accessibilityHidden(true)
                    .secretTap { demoModeToggle.toggle() }

                if isDemoMode {
                    DemoBadge()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("Вчерашние букеты")
                .font(DS.Typography.display)
                .foregroundStyle(DS.Palette.textPrimary)

            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                ForEach(points) { point in
                    row(point)
                }
            }

            Spacer(minLength: DS.Spacing.l)

            PrimaryButton("Смотреть букеты", systemImage: "arrow.right", action: onContinue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DS.Spacing.m)
        .padding(.bottom, DS.Spacing.m)
        .background(DS.Palette.bg)
    }

    private func row(_ point: Point) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.s) {
            Image(systemName: point.systemImage)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Palette.accent)
                // Ширина под иконку фиксирована, чтобы текст выстроился в колонку
                // даже при разной ширине символов.
                .frame(width: DS.Spacing.l, alignment: .leading)

            Text(point.text)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    OnboardingView {}
}
