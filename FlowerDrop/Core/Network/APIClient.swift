import SwiftUI

/// Ответ на запрос кода: сервер нормализует номер и говорит, сколько
/// код живёт. `debugCode` приходит только из dev-сборки бэкенда.
struct OTPChallenge: Hashable {
    let phone: String
    let expiresIn: Int
    let debugCode: String?
}

/// Успешный вход: токен и профиль.
struct AuthSession: Hashable {
    let token: String
    let phone: String
}

/// Контракт бэкенда. Экраны знают только его — за ним стоит либо сеть,
/// либо моки для превью.
protocol APIClient: Sendable {
    func bouquets() async throws -> [Bouquet]
    func bouquet(id: Int) async throws -> Bouquet

    func requestCode(phone: String) async throws -> OTPChallenge
    func verifyCode(phone: String, code: String) async throws -> AuthSession

    func reservations(token: String) async throws -> [Reservation]
    func reserve(bouquetID: Int, token: String) async throws -> Reservation
    func pickup(reservationID: Int, token: String) async throws -> Reservation

    /// Удалить аккаунт вместе с токеном. Требование App Store 5.1.1(v).
    func deleteAccount(token: String) async throws
}

private struct APIClientKey: EnvironmentKey {
    /// Превью и канвас работают на моках — без сети и без бэкенда.
    static let defaultValue: any APIClient = MockAPIClient()
}

extension EnvironmentValues {
    var apiClient: any APIClient {
        get { self[APIClientKey.self] }
        set { self[APIClientKey.self] = newValue }
    }
}
