import Foundation

/// Резервы живут в памяти до появления бэкенда.
/// Резерв держится два часа: после этого букет возвращается в остаток сам,
/// потому что остаток считается из резервов, а не хранится отдельно.
@MainActor
@Observable
final class ReservationStore {

    enum Status {
        case active
        case expired
        case pickedUp
    }

    struct Reservation: Identifiable, Hashable {
        let id: UUID
        let bouquet: Bouquet
        /// Код получения — его называют в лавке.
        let code: String
        let createdAt: Date
        var pickedUpAt: Date?

        var expiresAt: Date {
            createdAt.addingTimeInterval(ReservationStore.lifetime)
        }

        var expiresAtText: String {
            expiresAt.formatted(date: .omitted, time: .shortened)
        }

        func status(at moment: Date = Date()) -> Status {
            if pickedUpAt != nil { return .pickedUp }
            return moment < expiresAt ? .active : .expired
        }

        /// Сколько осталось до истечения на указанный момент.
        func timeLeft(at moment: Date) -> Duration {
            .seconds(max(0, expiresAt.timeIntervalSince(moment)))
        }
    }

    /// Два часа. Константа нужна и вне главного актора — из `Reservation`.
    nonisolated static let lifetime: TimeInterval = 2 * 60 * 60

    private(set) var reservations: [Reservation] = []

    /// Свежие сверху, истёкшие в конце.
    var sortedReservations: [Reservation] {
        reservations.sorted { left, right in
            let leftActive = left.status() == .active
            let rightActive = right.status() == .active
            if leftActive != rightActive { return leftActive }
            return left.createdAt > right.createdAt
        }
    }

    /// Остаток с учётом брони. Истёкшие резервы букет освобождают,
    /// полученные — нет.
    func remaining(for bouquet: Bouquet) -> Int {
        let taken = reservations
            .filter { $0.bouquet.id == bouquet.id && $0.status() != .expired }
            .count
        return max(0, bouquet.quantityLeft - taken)
    }

    @discardableResult
    func reserve(_ bouquet: Bouquet) -> Reservation {
        let reservation = Reservation(
            id: UUID(),
            bouquet: bouquet,
            code: Self.makeCode(),
            createdAt: Date(),
            pickedUpAt: nil
        )
        reservations.append(reservation)
        return reservation
    }

    func markPickedUp(_ id: UUID) {
        guard let index = reservations.firstIndex(where: { $0.id == id }) else { return }
        reservations[index].pickedUpAt = Date()
    }

    private static func makeCode() -> String {
        String(format: "%04d", Int.random(in: 0...9999))
    }
}
