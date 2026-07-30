import Foundation

/// Резервы живут в памяти до появления бэкенда.
/// Резерв держится два часа: после этого букет возвращается в остаток сам,
/// потому что остаток считается из активных резервов, а не хранится отдельно.
@MainActor
@Observable
final class ReservationStore {

    struct Reservation: Identifiable, Hashable {
        let id: UUID
        let bouquet: Bouquet
        /// Код получения — его называют в лавке.
        let code: String
        let createdAt: Date

        var expiresAt: Date {
            createdAt.addingTimeInterval(ReservationStore.lifetime)
        }

        var isActive: Bool {
            Date() < expiresAt
        }

        var expiresAtText: String {
            expiresAt.formatted(date: .omitted, time: .shortened)
        }
    }

    /// Два часа. Константа нужна и вне главного актора — из `Reservation`.
    nonisolated static let lifetime: TimeInterval = 2 * 60 * 60

    private(set) var reservations: [Reservation] = []

    var activeReservations: [Reservation] {
        reservations
            .filter(\.isActive)
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Остаток с учётом того, что уже зарезервировано и ещё не протухло.
    func remaining(for bouquet: Bouquet) -> Int {
        let taken = reservations
            .filter { $0.bouquet.id == bouquet.id && $0.isActive }
            .count
        return max(0, bouquet.quantityLeft - taken)
    }

    @discardableResult
    func reserve(_ bouquet: Bouquet) -> Reservation {
        let reservation = Reservation(
            id: UUID(),
            bouquet: bouquet,
            code: Self.makeCode(),
            createdAt: Date()
        )
        reservations.append(reservation)
        return reservation
    }

    private static func makeCode() -> String {
        String(format: "%04d", Int.random(in: 0...9999))
    }
}
