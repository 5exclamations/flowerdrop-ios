import Foundation

@MainActor
@Observable
final class FeedViewModel {

    enum State: Equatable {
        case loading
        case loaded([Bouquet])
        case empty
        case failed
    }

    private(set) var state: State = .loading

    private let client: APIClient

    init(client: APIClient = MockAPIClient()) {
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

    private func fetch() async {
        do {
            let items = try await client.bouquets()
            state = items.isEmpty ? .empty : .loaded(items)
        } catch is CancellationError {
            // Экран закрыли или потянули refresh заново — молча выходим.
        } catch {
            state = .failed
        }
    }
}
