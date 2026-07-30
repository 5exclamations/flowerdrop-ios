import Foundation

/// «Вчерашний» букет: лавка выкладывает его вечером со скидкой.
struct Bouquet: Identifiable, Hashable {
    let id: Int
    let title: String
    let summary: String
    let shopName: String
    let shopAddress: String
    /// Пустая строка в `photo_url` означает, что фотографии нет вовсе.
    let imageURL: URL?
    let originalPrice: Decimal
    let discountedPrice: Decimal
    /// Считает сервер — клиент не пересчитывает.
    let discountPercent: Int
    let pickupUntil: Date
    let quantityLeft: Int
    /// `null`, пока клиент не передаёт координаты.
    let distance: Measurement<UnitLength>?

    var isAvailable: Bool {
        quantityLeft > 0 && pickupUntil > Date()
    }

    var pickupUntilText: String {
        pickupUntil.formatted(date: .omitted, time: .shortened)
    }

    var distanceText: String? {
        distance?.formatted(.measurement(width: .abbreviated, usage: .road))
    }

    /// Подпись под названием: лавка и, если известно, расстояние.
    var shopLine: String {
        guard let distanceText else { return shopName }
        return "\(shopName) · \(distanceText)"
    }
}
