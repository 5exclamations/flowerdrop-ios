import Foundation

/// Ссылка на фотографию, вшитую в ассеты.
///
/// Демо-режим показывают без сети, а `Bouquet` умеет хранить только `URL`.
/// Поэтому фото подписывается собственной схемой: `BouquetPhoto` узнаёт её
/// и рисует картинку из каталога ассетов, ни разу не сходив в сеть.
enum DemoPhoto {
    private static let scheme = "flowerdrop-demo"

    static func url(asset: String) -> URL? {
        URL(string: "\(scheme)://\(asset)")
    }

    /// Имя ассета, если ссылка наша, и `nil` для обычных сетевых адресов.
    static func assetName(for url: URL) -> String? {
        guard url.scheme == scheme else { return nil }
        return url.host()
    }
}

/// Витрина для демо-режима и превью: три бакинские лавки и восемь букетов —
/// ровно те же, что `seed_demo` кладёт в бэкенд, чтобы показ вживую и показ
/// на моках выглядели одинаково.
///
/// Фотографии — Pexels (лицензия разрешает свободное использование),
/// уменьшены до 1200px по ширине и лежат в `Assets.xcassets/DemoPhotos`.
enum DemoCatalogue {

    /// Лавка закрывается в своё время — дедлайны в ленте должны различаться,
    /// иначе витрина выглядит сгенерированной.
    private struct Shop {
        let name: String
        let address: String
        let closingHour: Int
        let closingMinute: Int
        let distance: Double
    }

    private static let bakiBuket = Shop(
        name: "Bakı Buket",
        address: "ул. Низами, 28",
        closingHour: 21,
        closingMinute: 0,
        distance: 0.4
    )

    private static let gulEvi = Shop(
        name: "Gül Evi",
        address: "пр. Нефтяников, 14",
        closingHour: 22,
        closingMinute: 0,
        distance: 1.2
    )

    private static let icherisheherFlora = Shop(
        name: "İçərişəhər Flora",
        address: "ул. Кичик Гала, 12",
        closingHour: 20,
        closingMinute: 30,
        distance: 0.8
    )

    /// Сегодняшний дедлайн лавки. Считается при обращении, а не при запуске:
    /// приложение на показе может пережить полночь.
    private static func pickupUntil(_ shop: Shop) -> Date {
        let now = Date()
        return Calendar.current.date(
            bySettingHour: shop.closingHour,
            minute: shop.closingMinute,
            second: 0,
            of: now
        ) ?? now
    }

    private static func bouquet(
        id: Int,
        title: String,
        summary: String,
        shop: Shop,
        asset: String,
        originalPrice: Decimal,
        discountedPrice: Decimal,
        quantityLeft: Int
    ) -> Bouquet {
        Bouquet(
            id: id,
            title: title,
            summary: summary,
            shopName: shop.name,
            shopAddress: shop.address,
            imageURL: DemoPhoto.url(asset: asset),
            originalPrice: originalPrice,
            discountedPrice: discountedPrice,
            discountPercent: 50,
            pickupUntil: pickupUntil(shop),
            quantityLeft: quantityLeft,
            distance: Measurement(value: shop.distance, unit: .kilometers)
        )
    }

    static var bouquets: [Bouquet] {
        [
            bouquet(
                id: 1,
                title: "Тюльпаны в крафте",
                summary: "Двадцать пять тюльпанов в крафтовой бумаге. Собрали вчера утром, ночь простояли в холодильнике.",
                shop: bakiBuket,
                asset: "demo-tulips-kraft",
                originalPrice: 44,
                discountedPrice: 22,
                quantityLeft: 2
            ),
            bouquet(
                id: 2,
                title: "Розы и подсолнух",
                summary: "Оранжевые розы, подсолнух и хризантема. В прохладной воде простоит ещё неделю.",
                shop: gulEvi,
                asset: "demo-roses-sunflower",
                originalPrice: 58,
                discountedPrice: 29,
                quantityLeft: 1
            ),
            bouquet(
                id: 3,
                title: "Тюльпаны в бордо",
                summary: "Розовые тюльпаны в бордовой бумаге. Простой букет на каждый день, без лишнего декора.",
                shop: icherisheherFlora,
                asset: "demo-tulips-bordo",
                originalPrice: 30,
                discountedPrice: 15,
                quantityLeft: 3
            ),
            bouquet(
                id: 4,
                title: "Кустовые розы",
                summary: "Пастельные кустовые розы с эвкалиптом. Мелкие бутоны раскроются за пару дней.",
                shop: bakiBuket,
                asset: "demo-spray-roses",
                originalPrice: 36,
                discountedPrice: 18,
                quantityLeft: 2
            ),
            bouquet(
                id: 5,
                title: "Летний микс",
                summary: "Сборный букет из того, что осталось к вечеру: хризантемы, альстромерии и зелень.",
                shop: gulEvi,
                asset: "demo-summer-mix",
                originalPrice: 24,
                discountedPrice: 12,
                quantityLeft: 1
            ),
            bouquet(
                id: 6,
                title: "Ранункулюсы",
                summary: "Коралловые ранункулюсы в матовой плёнке. Бутоны раскроются полностью на второй день.",
                shop: icherisheherFlora,
                asset: "demo-ranunculus",
                originalPrice: 50,
                discountedPrice: 25,
                quantityLeft: 2
            ),
            bouquet(
                id: 7,
                title: "Пионы кораллом",
                summary: "Пионовидные розы кораллового оттенка. Крупные бутоны, плотная упаковка в два слоя.",
                shop: gulEvi,
                asset: "demo-peony-coral",
                originalPrice: 60,
                discountedPrice: 30,
                quantityLeft: 1
            ),
            bouquet(
                id: 8,
                title: "Анемоны и рускус",
                summary: "Фиолетовые анемоны с рускусом в зелёной бумаге. Небольшой букет для рабочего стола.",
                shop: bakiBuket,
                asset: "demo-anemones",
                originalPrice: 18,
                discountedPrice: 9,
                quantityLeft: 3
            )
        ]
    }
}
