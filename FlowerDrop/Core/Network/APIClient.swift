import SwiftUI

/// Кто подтвердил личность. Значение уходит в путь запроса, поэтому
/// совпадает с тем, что ждёт бэкенд.
enum AuthProvider: String, Sendable {
    case apple
    case google
}

/// Успешный вход: токен и профиль. Телефон теперь необязателен — это
/// контакт для лавки, а не способ войти.
struct AuthSession: Hashable {
    let token: String
    let phone: String?
    let email: String
    let name: String
}

/// Контракт бэкенда. Экраны знают только его — за ним стоит либо сеть,
/// либо моки для превью.
protocol APIClient: Sendable {
    func bouquets() async throws -> [Bouquet]
    func bouquet(id: Int) async throws -> Bouquet

    /// Обменять identity-токен провайдера на наш. Подпись проверяет сервер.
    func signIn(
        provider: AuthProvider,
        identityToken: String,
        name: String
    ) async throws -> AuthSession

    /// Телефон как контакт: пустая строка стирает его.
    func updatePhone(_ phone: String, token: String) async throws -> AuthSession

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
