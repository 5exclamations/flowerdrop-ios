import Foundation

/// Ошибки бэкенда по контракту. `code` стабилен — на нём и ветвимся,
/// `message` только для логов, пользователю показываем свой текст.
enum APIError: Error, Equatable {
    /// 404 — идентификатор неверный: карточку надо убрать из ленты.
    case notFound
    /// 409 — букет существует, но лента протухла: обновить и сказать,
    /// что кто-то оказался быстрее.
    case bouquetUnavailable
    case alreadyReserved
    case alreadyPickedUp
    case reservationExpired
    case otpInvalid
    case otpCooldown
    case throttled
    case notAuthenticated
    case accountDisabled
    case validation(fields: [String: [String]])
    /// Нет сети, таймаут, сервер лежит — состояние с повтором, а не крах.
    case unreachable
    case server(status: Int, code: String?)
    case decoding

    init(status: Int, code: String?, fields: [String: [String]]?) {
        switch (status, code) {
        case (404, _): self = .notFound
        case (409, "bouquet_unavailable"): self = .bouquetUnavailable
        case (409, "already_reserved"): self = .alreadyReserved
        case (409, "already_picked_up"): self = .alreadyPickedUp
        case (409, "reservation_expired"): self = .reservationExpired
        case (400, "otp_invalid"): self = .otpInvalid
        case (429, "otp_cooldown"): self = .otpCooldown
        case (429, _): self = .throttled
        case (401, _): self = .notAuthenticated
        case (403, "account_disabled"): self = .accountDisabled
        case (400, _): self = .validation(fields: fields ?? [:])
        default: self = .server(status: status, code: code)
        }
    }

    /// Показывать ли состояние «повторить»: сеть и пятисотки лечатся повтором,
    /// остальное — нет.
    var isRetryable: Bool {
        switch self {
        case .unreachable: true
        case .server(let status, _): status >= 500
        default: false
        }
    }
}
