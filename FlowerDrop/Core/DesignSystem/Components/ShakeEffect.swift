import SwiftUI

/// Горизонтальная тряска для ошибки ввода.
/// Один шаг `animatableData` — одна серия колебаний.
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = DS.Spacing.xs
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: amount * sin(animatableData * .pi * shakesPerUnit),
                y: 0
            )
        )
    }
}
