import Foundation

/// Бэкенд демо-режима: весь флоу живёт в памяти приложения.
///
/// В отличие от `MockAPIClient`, который отвечает одним и тем же и годится
/// только для превью, этот клиент помнит, что произошло: остаток уменьшается,
/// резерв появляется во вкладке, «Забрал» меняет статус. Без этого показ
/// разваливается на первом же шаге после резерва.
///
/// Актор, а не класс: `APIClient` требует `Sendable`, а состояние здесь
/// меняется из разных задач.
actor DemoAPIClient: APIClient {

    private static let token = "demo-token"
    /// Резерв держится два часа, но не дольше, чем открыта лавка.
    private static let reservationTTL: TimeInterval = 2 * 60 * 60
    /// Крошечная задержка: без неё скелетоны не успевают показаться и
    /// демонстрация выглядит беднее, чем приложение на самом деле.
    private static let latency: Duration = .milliseconds(350)

    private var catalogue: [Bouquet]
    private var reservations: [Reservation] = []
    private var nextReservationID = 1
    private var phone: String?
    private var name = "Гость"

    init(catalogue: [Bouquet] = DemoCatalogue.bouquets) {
        self.catalogue = catalogue
    }

    // MARK: - Каталог

    func bouquets() async throws -> [Bouquet] {
        try await pause()
        return catalogue.filter(\.isAvailable)
    }

    func bouquet(id: Int) async throws -> Bouquet {
        try await pause()
        guard let bouquet = catalogue.first(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        return bouquet
    }

    // MARK: - Вход

    /// На показе вход не ходит к Apple и Google: их сессии требуют сети и
    /// живого аккаунта, а демо обязано работать в самолёте. Экран входа
    /// отдаёт сюда любой токен, и мы его принимаем — подделывается ровно
    /// внешний шаг, всё остальное после входа настоящее.
    func signIn(
        provider: AuthProvider,
        identityToken: String,
        name: String
    ) async throws -> AuthSession {
        try await pause()
        self.name = name.isEmpty ? self.name : name
        return session
    }

    func updatePhone(_ phone: String, token: String) async throws -> AuthSession {
        try await pause()
        try check(token)
        self.phone = phone.isEmpty ? nil : phone
        return session
    }

    private var session: AuthSession {
        AuthSession(token: Self.token, phone: phone, email: "demo@flowerdrop.az", name: name)
    }

    // MARK: - Резервы

    func reservations(token: String) async throws -> [Reservation] {
        try await pause()
        try check(token)
        return reservations.sorted { $0.createdAt > $1.createdAt }
    }

    func reserve(bouquetID: Int, token: String) async throws -> Reservation {
        try await pause()
        try check(token)

        guard let index = catalogue.firstIndex(where: { $0.id == bouquetID }) else {
            throw APIError.notFound
        }
        let bouquet = catalogue[index]
        guard bouquet.isAvailable else { throw APIError.bouquetUnavailable }

        catalogue[index] = bouquet.withQuantityLeft(bouquet.quantityLeft - 1)

        let now = Date()
        let reservation = Reservation(
            id: nextReservationID,
            bouquet: catalogue[index],
            code: Self.freshCode(),
            status: .active,
            createdAt: now,
            expiresAt: min(now.addingTimeInterval(Self.reservationTTL), bouquet.pickupUntil),
            pickedUpAt: nil
        )
        nextReservationID += 1
        reservations.append(reservation)
        return reservation
    }

    func pickup(reservationID: Int, token: String) async throws -> Reservation {
        try await pause()
        try check(token)

        guard let index = reservations.firstIndex(where: { $0.id == reservationID }) else {
            throw APIError.notFound
        }
        let reservation = reservations[index]
        guard reservation.status == .active else { throw APIError.alreadyPickedUp }

        let picked = reservation.pickedUp(at: Date())
        reservations[index] = picked
        return picked
    }

    // MARK: - Аккаунт

    /// Удаление имитируется: на показе нечего удалять на сервере, но зритель
    /// должен увидеть тот же результат — брони исчезли, остаток вернулся.
    func deleteAccount(token: String) async throws {
        try await pause()
        try check(token)
        for reservation in reservations where reservation.status == .active {
            if let index = catalogue.firstIndex(where: { $0.id == reservation.bouquet.id }) {
                let bouquet = catalogue[index]
                catalogue[index] = bouquet.withQuantityLeft(bouquet.quantityLeft + 1)
            }
        }
        reservations.removeAll()
    }

    // MARK: - Служебное

    private func check(_ token: String) throws {
        guard token == Self.token else { throw APIError.notAuthenticated }
    }

    private func pause() async throws {
        try await Task.sleep(for: Self.latency)
    }

    /// Четыре цифры, как у настоящего бэкенда — на показе код должен
    /// каждый раз быть новым, иначе выглядит как заглушка.
    private static func freshCode() -> String {
        String(format: "%04d", Int.random(in: 0...9999))
    }
}

// Копии с одним изменённым полем. Модели неизменяемые и такими остаются:
// на бэкенде состояние считает сервер, и эти помощники нужны только тому,
// кто его подменяет.

private extension Bouquet {
    func withQuantityLeft(_ value: Int) -> Bouquet {
        Bouquet(
            id: id,
            title: title,
            summary: summary,
            shopName: shopName,
            shopAddress: shopAddress,
            imageURL: imageURL,
            originalPrice: originalPrice,
            discountedPrice: discountedPrice,
            discountPercent: discountPercent,
            pickupUntil: pickupUntil,
            quantityLeft: value,
            distance: distance
        )
    }
}

private extension Reservation {
    func pickedUp(at moment: Date) -> Reservation {
        Reservation(
            id: id,
            bouquet: bouquet,
            code: code,
            status: .pickedUp,
            createdAt: createdAt,
            expiresAt: expiresAt,
            pickedUpAt: moment
        )
    }
}
