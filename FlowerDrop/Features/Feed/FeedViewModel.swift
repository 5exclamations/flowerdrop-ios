import Foundation

@MainActor
@Observable
final class FeedViewModel {

    enum State: Equatable {
        case loading
        case loaded([Bouquet])
        case empty
        /// `retryable` — сеть или пятисотка: показываем кнопку повтора.
        case failed(retryable: Bool)
    }

    private(set) var state: State = .loading

    private let client: any APIClient

    init(client: any APIClient) {
        self.client = client
    }

    func load() async {
        state = .loading
        await fetch()
    }

    /// Pull-to-refresh не сбрасывает ленту в скелетоны — это выглядело бы
    /// как дёрганье уже показанного контента.
    func refresh() async {
        await fetch()
    }

    /// 404 по букету: идентификатор неверный, карточке в ленте не место.
    func remove(id: Int) {
        guard case .loaded(let items) = state else { return }
        let rest = items.filter { $0.id != id }
        state = rest.isEmpty ? .empty : .loaded(rest)
    }

    /// Свежие данные по одному букету — после проигранной гонки за остаток.
    func replace(_ bouquet: Bouquet) {
        guard case .loaded(let items) = state else { return }
        state = .loaded(items.map { $0.id == bouquet.id ? bouquet : $0 })
    }

    private func fetch() async {
        do {
            let items = try await client.bouquets()
            state = items.isEmpty ? .empty : .loaded(items)
        } catch is CancellationError {
            // Экран закрыли или потянули refresh заново — молча выходим.
        } catch let error as APIError {
            state = .failed(retryable: error.isRetryable)
        } catch {
            state = .failed(retryable: true)
        }
    }
}
