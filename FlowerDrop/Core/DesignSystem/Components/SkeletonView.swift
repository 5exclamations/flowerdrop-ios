import SwiftUI

/// Плейсхолдер загрузки с бегущим бликом.
/// Кадры считает TimelineView, поэтому блик не зависит от неявных анимаций
/// и корректно замирает при включённом «уменьшении движения».
struct SkeletonView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            DS.Radius.shape
                .fill(DS.Palette.textSecondary.opacity(DS.Opacity.subtle))
                .overlay {
                    DS.Radius.shape
                        .fill(shimmer(phase: Self.phase(at: context.date)))
                }
        }
        .accessibilityHidden(true)
    }

    /// Блик пробегает слева направо за `DS.Motion.shimmerDuration`.
    private static func phase(at date: Date) -> CGFloat {
        let duration = DS.Motion.shimmerDuration
        let progress = date.timeIntervalSinceReferenceDate
            .truncatingRemainder(dividingBy: duration) / duration
        return -0.4 + CGFloat(progress) * 1.8
    }

    private func shimmer(phase: CGFloat) -> LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: DS.Palette.textSecondary.opacity(DS.Opacity.medium), location: 0.5),
                .init(color: .clear, location: 1)
            ],
            startPoint: UnitPoint(x: phase - 0.3, y: 0.5),
            endPoint: UnitPoint(x: phase + 0.3, y: 0.5)
        )
    }
}

#Preview {
    VStack(alignment: .leading, spacing: DS.Spacing.s) {
        SkeletonView()
            .aspectRatio(DS.Size.photoAspectRatio, contentMode: .fit)
        SkeletonView().frame(height: DS.Spacing.m)
        SkeletonView().frame(height: DS.Spacing.s)
    }
    .padding(DS.Spacing.m)
    .background(DS.Palette.bg)
}
