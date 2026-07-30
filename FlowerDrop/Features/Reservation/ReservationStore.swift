import Foundation

/// Резервы теперь живут на сервере: он же гасит просроченные и возвращает
/// остаток в ленту. Клиент ничего не считает сам.
@MainActor
@Observable
final class ReservationStore {

    enum State: Equatable {
        case loading
        case loaded([Reservation])
        case empty
        case failed(retryable: Bool)
    }

    private(set) var state: State = .loading

    private let client: any APIClient
    private let auth: AuthStore

    init(client: any APIClient, auth: AuthStore) {
        self.client = client
        self.auth = auth
    }

    func load() async {
        state = .loading
        await fetch()
    }

    func refresh() async {
        await fetch()
    }

    /// Бронь. Ошибки контракта пробрасываем наверх — экран букета решает,
    /// что показать: 409 это «разобрали», 404 — «карточки больше нет».
    func reserve(_ bouquet: Bouquet) async throws -> Reservation {
        guard let token = auth.token else { throw APIError.notAuthenticated }
        let reservation = try await client.reserve(bouquetID: bouquet.id, token: token)
        await fetch()
        return reservation
    }

    func pickup(_ reservation: Reservation) async {
        guard let token = auth.token else { return }
        do {
            _ = try await client.pickup(reservationID: reservation.id, token: token)
        } catch {
            // Сервер уже мог закрыть бронь сам — просто перечитываем список.
        }
        await fetch()
    }

    private func fetch() async {
        guard let token = auth.token else {
            state = .empty
            return
        }
        do {
            let items = try await client.reservations(token: token)
            state = items.isEmpty ? .empty : .loaded(items)
        } catch is CancellationError {
            // Экран закрыли — молча выходим.
        } catch let error as APIError {
            if error == .notAuthenticated {
                auth.signOut()
                state = .empty
            } else {
                state = .failed(retryable: error.isRetryable)
            }
        } catch {
            state = .failed(retryable: true)
        }
    }
}
