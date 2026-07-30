import Foundation

/// Бронь букета. Статус считает сервер: он же гасит просроченные
/// при любом обращении к эндпоинтам резервов.
struct Reservation: Identifiable, Hashable {
    enum Status: String {
        case active
        case expired
        case pickedUp
    }

    let id: Int
    let bouquet: Bouquet
    /// Код получения — его называют в лавке.
    let code: String
    let status: Status
    let createdAt: Date
    let expiresAt: Date
    let pickedUpAt: Date?

    var expiresAtText: String {
        expiresAt.formatted(date: .omitted, time: .shortened)
    }

    /// Сколько осталось до истечения на указанный момент.
    func timeLeft(at moment: Date) -> Duration {
        .seconds(max(0, expiresAt.timeIntervalSince(moment)))
    }

    /// Сервер отдаёт статус на момент ответа, но между обновлениями список
    /// живёт на экране — поэтому истечение проверяем и по часам.
    func status(at moment: Date) -> Status {
        guard status == .active else { return status }
        return moment < expiresAt ? .active : .expired
    }
}
