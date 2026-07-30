import Foundation

/// «Вчерашний» букет: лавка выкладывает его вечером со скидкой -50%.
struct Bouquet: Identifiable, Hashable {
    let id: UUID
    let title: String
    let summary: String
    let shopName: String
    let shopAddress: String
    let imageURL: URL
    let originalPrice: Decimal
    let discountedPrice: Decimal
    /// Конец окна самовывоза — сегодня.
    let pickupUntil: Date
    let quantityLeft: Int
    let distance: Measurement<UnitLength>

    var discountPercent: Int {
        guard originalPrice > 0, discountedPrice < originalPrice else { return 0 }
        let ratio = (originalPrice - discountedPrice) / originalPrice
        return Int((NSDecimalNumber(decimal: ratio).doubleValue * 100).rounded())
    }

    var pickupUntilText: String {
        pickupUntil.formatted(date: .omitted, time: .shortened)
    }

    var distanceText: String {
        distance.formatted(
            .measurement(width: .abbreviated, usage: .road)
        )
    }
}
