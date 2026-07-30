import Foundation

/// Моки для превью и канваса: без сети, без бэкенда, детерминированные данные.
/// В приложении не используется — там RealAPIClient.
struct MockAPIClient: APIClient {

    var latency: Duration = .zero

    func bouquets() async throws -> [Bouquet] {
        try await pause()
        return Self.catalogue
    }

    func bouquet(id: Int) async throws -> Bouquet {
        try await pause()
        guard let bouquet = Self.catalogue.first(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        return bouquet
    }

    func requestCode(phone: String) async throws -> OTPChallenge {
        try await pause()
        return OTPChallenge(phone: phone, expiresIn: 300, debugCode: "1111")
    }

    func verifyCode(phone: String, code: String) async throws -> AuthSession {
        try await pause()
        guard code == "1111" else { throw APIError.otpInvalid }
        return AuthSession(token: "preview-token", phone: phone)
    }

    func reservations(token: String) async throws -> [Reservation] {
        try await pause()
        return [Self.reservation]
    }

    func reserve(bouquetID: Int, token: String) async throws -> Reservation {
        try await pause()
        guard let bouquet = Self.catalogue.first(where: { $0.id == bouquetID }) else {
            throw APIError.notFound
        }
        return Reservation(
            id: bouquetID,
            bouquet: bouquet,
            code: "1111",
            status: .active,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(2 * 60 * 60),
            pickedUpAt: nil
        )
    }

    func pickup(reservationID: Int, token: String) async throws -> Reservation {
        try await pause()
        return Self.reservation
    }

    private func pause() async throws {
        guard latency > .zero else { return }
        try await Task.sleep(for: latency)
    }

    // MARK: - Данные

    private static func photo(_ id: Int) -> URL? {
        URL(string: "https://images.pexels.com/photos/\(id)/pexels-photo-\(id).jpeg?auto=compress&cs=tinysrgb&w=900")
    }

    private static var pickupUntil: Date {
        Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
    }

    static let catalogue: [Bouquet] = [
        Bouquet(
            id: 1,
            title: "Тюльпаны в крафте",
            summary: "Двадцать пять тюльпанов в крафтовой бумаге. Собрали вчера утром, ночь простояли в холодильнике.",
            shopName: "Bakı Buket",
            shopAddress: "ул. Низами, 28",
            imageURL: photo(36945270),
            originalPrice: 44,
            discountedPrice: 22,
            discountPercent: 50,
            pickupUntil: pickupUntil,
            quantityLeft: 2,
            distance: Measurement(value: 0.4, unit: .kilometers)
        ),
        Bouquet(
            id: 2,
            title: "Розы и подсолнух",
            summary: "Оранжевые розы, подсолнух и хризантема. В прохладной воде простоит ещё неделю.",
            shopName: "Gül Evi",
            shopAddress: "пр. Нефтяников, 14",
            imageURL: photo(37222812),
            originalPrice: 58,
            discountedPrice: 29,
            discountPercent: 50,
            pickupUntil: pickupUntil,
            quantityLeft: 1,
            distance: Measurement(value: 1.2, unit: .kilometers)
        ),
        Bouquet(
            id: 3,
            title: "Тюльпаны в бордо",
            summary: "Розовые тюльпаны в бордовой бумаге. Простой букет на каждый день, без лишнего декора.",
            shopName: "Nərgiz Çiçək",
            shopAddress: "ул. Ази Асланова, 7",
            imageURL: photo(7311450),
            originalPrice: 30,
            discountedPrice: 15,
            discountPercent: 50,
            pickupUntil: pickupUntil,
            quantityLeft: 3,
            distance: Measurement(value: 0.8, unit: .kilometers)
        ),
        Bouquet(
            id: 4,
            title: "Кустовые розы",
            summary: "Пастельные кустовые розы с эвкалиптом. Мелкие бутоны раскроются за пару дней.",
            shopName: "Lalə Studio",
            shopAddress: "ул. Ахмеда Джавада, 3",
            imageURL: photo(20295105),
            originalPrice: 36,
            discountedPrice: 18,
            discountPercent: 50,
            pickupUntil: pickupUntil,
            quantityLeft: 2,
            distance: Measurement(value: 1.7, unit: .kilometers)
        )
    ]

    static let reservation = Reservation(
        id: 1,
        bouquet: catalogue[0],
        code: "7412",
        status: .active,
        createdAt: Date(),
        expiresAt: Date().addingTimeInterval(2 * 60 * 60),
        pickedUpAt: nil
    )
}
