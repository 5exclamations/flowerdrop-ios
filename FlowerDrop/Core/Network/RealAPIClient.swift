import Foundation

/// Клиент реального бэкенда. Слеши в путях важны: у списков они есть,
/// у `auth/*`, `account` и `pickup` — нет (см. API_CONTRACT.md).
struct RealAPIClient: APIClient {
    let baseURL: URL
    let session: URLSession

    init(baseURL: URL = APIConfiguration.baseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    // MARK: - Букеты

    func bouquets() async throws -> [Bouquet] {
        let dtos: [BouquetDTO] = try await get("api/bouquets/")
        return dtos.map(\.model)
    }

    func bouquet(id: Int) async throws -> Bouquet {
        let dto: BouquetDTO = try await get("api/bouquets/\(id)/")
        return dto.model
    }

    // MARK: - Вход

    func signIn(
        provider: AuthProvider,
        identityToken: String,
        name: String
    ) async throws -> AuthSession {
        // Провайдер в пути, а не в теле — так решил контракт: клиент не
        // может попросить проверить токен чужими ключами.
        let dto: SignInDTO = try await post(
            "api/auth/\(provider.rawValue)",
            body: ["identity_token": identityToken, "name": name]
        )
        return dto.session
    }

    func updatePhone(_ phone: String, token: String) async throws -> AuthSession {
        var request = URLRequest(url: baseURL.appending(path: "api/account"))
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["phone": phone])
        let dto: UserDTO = try await send(request, token: token)
        // Токен не меняется — сервер вернул только профиль.
        return AuthSession(token: token, phone: dto.phone, email: dto.email, name: dto.name)
    }

    // MARK: - Резервы

    func reservations(token: String) async throws -> [Reservation] {
        let dtos: [ReservationDTO] = try await get("api/reservations/", token: token)
        return dtos.map(\.model)
    }

    func reserve(bouquetID: Int, token: String) async throws -> Reservation {
        let dto: ReservationDTO = try await post(
            "api/reservations/",
            body: ["bouquet_id": bouquetID],
            token: token
        )
        return dto.model
    }

    func pickup(reservationID: Int, token: String) async throws -> Reservation {
        let dto: ReservationDTO = try await post(
            "api/reservations/\(reservationID)/pickup",
            body: [String: String](),
            token: token
        )
        return dto.model
    }

    // MARK: - Аккаунт

    func deleteAccount(token: String) async throws {
        // Без слеша на конце — см. API_CONTRACT.md.
        var request = URLRequest(url: baseURL.appending(path: "api/account"))
        request.httpMethod = "DELETE"
        try await send(request, token: token)
    }

    // MARK: - Транспорт

    private func get<Response: Decodable>(
        _ path: String,
        token: String? = nil
    ) async throws -> Response {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = "GET"
        return try await send(request, token: token)
    }

    private func post<Body: Encodable, Response: Decodable>(
        _ path: String,
        body: Body,
        token: String? = nil
    ) async throws -> Response {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return try await send(request, token: token)
    }

    private func send<Response: Decodable>(
        _ request: URLRequest,
        token: String?
    ) async throws -> Response {
        let data = try await perform(request, token: token)
        do {
            return try Self.decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }

    /// Тело ответа не нужно: 204 у него пустое, а декодер на пустоте падает.
    private func send(_ request: URLRequest, token: String?) async throws {
        _ = try await perform(request, token: token)
    }

    private func perform(_ request: URLRequest, token: String?) async throws -> Data {
        var request = request
        if let token {
            request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch {
            throw APIError.unreachable
        }

        guard let http = response as? HTTPURLResponse else { throw APIError.unreachable }

        guard (200..<300).contains(http.statusCode) else {
            let envelope = try? JSONDecoder().decode(ErrorEnvelopeDTO.self, from: data)
            throw APIError(
                status: http.statusCode,
                code: envelope?.error.code,
                fields: envelope?.error.fields
            )
        }

        return data
    }

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

// MARK: - DTO

private struct UserDTO: Decodable {
    let phone: String?
    let email: String
    let name: String
}

private struct SignInDTO: Decodable {
    let token: String
    let user: UserDTO

    var session: AuthSession {
        AuthSession(token: token, phone: user.phone, email: user.email, name: user.name)
    }
}

private struct ErrorEnvelopeDTO: Decodable {
    struct Payload: Decodable {
        let code: String
        let message: String
        let fields: [String: [String]]?
    }
    let error: Payload
}

private struct ShopDTO: Decodable {
    let name: String
    let address: String
}

private struct BouquetDTO: Decodable {
    let id: Int
    let title: String
    let description: String
    let photoURL: String
    let priceOld: String
    let priceNew: String
    let discountPercent: Int
    let qtyLeft: Int
    let pickupUntil: Date
    let distanceKm: Double?
    let shop: ShopDTO

    enum CodingKeys: String, CodingKey {
        case id, title, description, shop
        case photoURL = "photo_url"
        case priceOld = "price_old"
        case priceNew = "price_new"
        case discountPercent = "discount_percent"
        case qtyLeft = "qty_left"
        case pickupUntil = "pickup_until"
        case distanceKm = "distance_km"
    }

    var model: Bouquet {
        Bouquet(
            id: id,
            title: title,
            summary: description,
            shopName: shop.name,
            shopAddress: shop.address,
            imageURL: photoURL.isEmpty ? nil : URL(string: photoURL),
            originalPrice: Self.money(priceOld),
            discountedPrice: Self.money(priceNew),
            discountPercent: discountPercent,
            pickupUntil: pickupUntil,
            quantityLeft: qtyLeft,
            distance: distanceKm.map { Measurement(value: $0, unit: UnitLength.kilometers) }
        )
    }

    /// Деньги приходят строкой, чтобы никто не превратил их во float.
    /// Локаль фиксированная: с русской «22.00» разобралась бы как 2200.
    private static func money(_ raw: String) -> Decimal {
        Decimal(string: raw, locale: Locale(identifier: "en_US_POSIX")) ?? 0
    }
}

private struct ReservationDTO: Decodable {
    let id: Int
    let code: String
    let status: String
    let createdAt: Date
    let expiresAt: Date
    let pickedUpAt: Date?
    let bouquet: BouquetDTO

    enum CodingKeys: String, CodingKey {
        case id, code, status, bouquet
        case createdAt = "created_at"
        case expiresAt = "expires_at"
        case pickedUpAt = "picked_up_at"
    }

    var model: Reservation {
        Reservation(
            id: id,
            bouquet: bouquet.model,
            code: code,
            status: Reservation.Status(rawValue: status == "picked_up" ? "pickedUp" : status) ?? .active,
            createdAt: createdAt,
            expiresAt: expiresAt,
            pickedUpAt: pickedUpAt
        )
    }
}
