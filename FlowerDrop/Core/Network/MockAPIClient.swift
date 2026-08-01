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

    func deleteAccount(token: String) async throws {
        try await pause()
    }

    private func pause() async throws {
        guard latency > .zero else { return }
        try await Task.sleep(for: latency)
    }

    // MARK: - Данные

    /// Витрина общая с демо-режимом: превью показывают то же, что увидит
    /// зритель на показе.
    static var catalogue: [Bouquet] { DemoCatalogue.bouquets }

    static let reservation = Reservation(
        id: 1,
        bouquet: DemoCatalogue.bouquets[0],
        code: "7412",
        status: .active,
        createdAt: Date(),
        expiresAt: Date().addingTimeInterval(2 * 60 * 60),
        pickedUpAt: nil
    )
}
