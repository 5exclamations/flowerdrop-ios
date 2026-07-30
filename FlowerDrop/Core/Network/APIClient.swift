import Foundation

/// Контракт бэкенда. Django REST появится позже — вьюмодели уже сейчас
/// работают только через этот протокол.
protocol APIClient: Sendable {
    func bouquets() async throws -> [Bouquet]
}

/// Моки на время, пока бэкенда нет.
/// Фотографии — реальные URL Pexels, каждый проверен на отдачу image/jpeg.
struct MockAPIClient: APIClient {

    /// Задержка, чтобы скелетоны были не декорацией, а рабочим состоянием.
    var latency: Duration = .milliseconds(1500)

    func bouquets() async throws -> [Bouquet] {
        try await Task.sleep(for: latency)
        return Self.catalogue
    }

    private static func photo(_ id: Int) -> URL {
        URL(string: "https://images.pexels.com/photos/\(id)/pexels-photo-\(id).jpeg?auto=compress&cs=tinysrgb&w=900")!
    }

    /// Сегодня в 21:00 — единое окно самовывоза для всех лавок.
    private static var pickupUntil: Date {
        Calendar.current.date(
            bySettingHour: 21,
            minute: 0,
            second: 0,
            of: Date()
        ) ?? Date()
    }

    private static let catalogue: [Bouquet] = [
        Bouquet(
            id: UUID(uuidString: "A1000000-0000-0000-0000-000000000001")!,
            title: "Тюльпаны в крафте",
            shopName: "Bakı Buket",
            imageURL: photo(36945270),
            originalPrice: 44,
            discountedPrice: 22,
            pickupUntil: pickupUntil,
            quantityLeft: 2,
            distance: Measurement(value: 0.4, unit: .kilometers)
        ),
        Bouquet(
            id: UUID(uuidString: "A1000000-0000-0000-0000-000000000002")!,
            title: "Розы и подсолнух",
            shopName: "Gül Evi",
            imageURL: photo(37222812),
            originalPrice: 58,
            discountedPrice: 29,
            pickupUntil: pickupUntil,
            quantityLeft: 1,
            distance: Measurement(value: 1.2, unit: .kilometers)
        ),
        Bouquet(
            id: UUID(uuidString: "A1000000-0000-0000-0000-000000000003")!,
            title: "Тюльпаны в бордо",
            shopName: "Nərgiz Çiçək",
            imageURL: photo(7311450),
            originalPrice: 30,
            discountedPrice: 15,
            pickupUntil: pickupUntil,
            quantityLeft: 3,
            distance: Measurement(value: 0.8, unit: .kilometers)
        ),
        Bouquet(
            id: UUID(uuidString: "A1000000-0000-0000-0000-000000000004")!,
            title: "Кустовые розы",
            shopName: "Lalə Studio",
            imageURL: photo(20295105),
            originalPrice: 36,
            discountedPrice: 18,
            pickupUntil: pickupUntil,
            quantityLeft: 2,
            distance: Measurement(value: 1.7, unit: .kilometers)
        ),
        Bouquet(
            id: UUID(uuidString: "A1000000-0000-0000-0000-000000000005")!,
            title: "Летний микс",
            shopName: "Səhər Gülləri",
            imageURL: photo(20617542),
            originalPrice: 24,
            discountedPrice: 12,
            pickupUntil: pickupUntil,
            quantityLeft: 1,
            distance: Measurement(value: 2.3, unit: .kilometers)
        ),
        Bouquet(
            id: UUID(uuidString: "A1000000-0000-0000-0000-000000000006")!,
            title: "Ранункулюсы",
            shopName: "İçərişəhər Flora",
            imageURL: photo(20704831),
            originalPrice: 50,
            discountedPrice: 25,
            pickupUntil: pickupUntil,
            quantityLeft: 2,
            distance: Measurement(value: 0.3, unit: .kilometers)
        ),
        Bouquet(
            id: UUID(uuidString: "A1000000-0000-0000-0000-000000000007")!,
            title: "Пионы кораллом",
            shopName: "Fəvvarə Çiçək",
            imageURL: photo(5656731),
            originalPrice: 60,
            discountedPrice: 30,
            pickupUntil: pickupUntil,
            quantityLeft: 1,
            distance: Measurement(value: 3.6, unit: .kilometers)
        ),
        Bouquet(
            id: UUID(uuidString: "A1000000-0000-0000-0000-000000000008")!,
            title: "Анемоны и рускус",
            shopName: "Nizami Gül Bazar",
            imageURL: photo(23094210),
            originalPrice: 18,
            discountedPrice: 9,
            pickupUntil: pickupUntil,
            quantityLeft: 3,
            distance: Measurement(value: 2.9, unit: .kilometers)
        )
    ]
}
